CREATE OR ALTER PROCEDURE dbo.spETLCargaOperacionEmpleado
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
BEGIN TRY

    SET @outResultCode = 0;

    DECLARE @xmlData XML;
    SELECT @xmlData = CAST(BulkColumn AS XML)
    FROM OPENROWSET(BULK '/scripts/data/operaciones.xml', SINGLE_BLOB) AS x;

    DECLARE @FechaActual DATE;
    DECLARE @ResultCode INT = 0;

    -- Variables loop marcas
    DECLARE @VarDoc VARCHAR(20);
    DECLARE @VarEntrada DATETIME;
    DECLARE @VarSalida DATETIME;
    DECLARE @iMarca INT;
    DECLARE @totalMarcas INT;
    DECLARE @MsgErr NVARCHAR(250);

    DECLARE @TablaFechas TABLE (
        Fecha DATE PRIMARY KEY
    );

    DECLARE @TablaMarcasDias TABLE (
        Seq INT IDENTITY(1,1) PRIMARY KEY
        , ValDoc VARCHAR(20)
        , Entrada DATETIME
        , Salida DATETIME
    );

    -- Extraer las fechas únicas del archivo XML
    INSERT @TablaFechas (Fecha)
    SELECT DISTINCT T.Item.value('@Fecha', 'DATE')
    FROM @xmlData.nodes('/Operaciones/FechaOperacion') AS T(Item);

    SELECT @FechaActual = MIN(Fecha) FROM @TablaFechas;

    BEGIN TRANSACTION;

    WHILE (@FechaActual IS NOT NULL)
    BEGIN

        -- ============================================================
        -- 1. INSERTAR NUEVOS EMPLEADOS
        -- ============================================================
        INSERT dbo.Empleado 
        (
            idPuesto
            ,idUsuario
            ,ValorDocumento
            ,Nombre
            ,CuentaBancaria
            ,FechaContratacion
            ,Activo
        )
        SELECT 
            P.id
            ,U.id -- Quedará en NULL si el empleado no tiene un usuario previo en la tabla Usuario
            ,T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(30)')
            ,T.Item.value('@Nombre', 'VARCHAR(150)')
            ,T.Item.value('@CuentaBancaria', 'VARCHAR(30)')
            ,ISNULL(T.Item.value('@FechaContratacion', 'DATE'), @FechaActual)
            ,1 -- Activo por defecto
        FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/InsertarEmpleado') AS T(Item)
        INNER JOIN dbo.Puesto AS P 
            ON P.Nombre = T.Item.value('@Puesto', 'VARCHAR(100)')
        LEFT JOIN dbo.Usuario AS U 
            ON U.Username = T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(30)');


        -- ============================================================
        -- 2. ELIMINAR / INACTIVAR EMPLEADOS
        -- ============================================================
        UPDATE E WITH(ROWLOCK) 
        SET E.Activo = 0
        FROM dbo.Empleado E
        INNER JOIN (
            SELECT T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(30)') AS ValDoc
            FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/EliminarEmpleado') AS T(Item)
        ) AS XML_Eliminar 
            ON E.ValorDocumento = XML_Eliminar.ValDoc;


        -- ============================================================
        -- 3. ASOCIAR DEDUCCIONES NO OBLIGATORIAS
        -- ============================================================
        INSERT dbo.DeduccionEmpleado (idEmpleado, idTipoDeduccion, MontoFijo, FechaInicio, FechaFin)
        SELECT
            E.id
            , TD.id
            , T.Item.value('@MontoFijo', 'DECIMAL(10,2)')
            , @FechaActual
            , '9999-12-31'
        FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/AsociaEmpleadoConDeduccion') AS T(Item)
        INNER JOIN dbo.Empleado AS E 
            ON E.ValorDocumento = T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)')
        INNER JOIN dbo.TipoDeduccion AS TD 
            ON TD.Nombre = T.Item.value('@TipoDeduccion', 'VARCHAR(100)');


        -- ============================================================
        -- 4. DESASOCIAR DEDUCCIONES (CERRAR VIGENCIA)
        -- ============================================================
        UPDATE DE WITH(ROWLOCK)
        SET DE.FechaFin = @FechaActual
        FROM dbo.DeduccionEmpleado AS DE
        INNER JOIN dbo.Empleado AS E 
            ON DE.idEmpleado = E.id
        INNER JOIN (
            SELECT
                T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)') AS ValDoc
                , TD.id AS idTipoDeduccion
            FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/DesasociaEmpleadoConDeduccion') AS T(Item)
            INNER JOIN dbo.TipoDeduccion AS TD 
                ON TD.Nombre = T.Item.value('@TipoDeduccion', 'VARCHAR(100)')
        ) AS Desasoc 
            ON E.ValorDocumento = Desasoc.ValDoc 
            AND DE.idTipoDeduccion = Desasoc.idTipoDeduccion
        WHERE DE.FechaFin >= '9999-12-31';


        -- ============================================================
        -- 5. ASIGNAR JORNADAS HORARIAS
        -- ============================================================
        INSERT dbo.HorarioJornada (idEmpleado, idSemana, idTipoJornada)
        SELECT
            E.id
            , S.id
            , TJ.id
        FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/AsignarJornada') AS T(Item)
        INNER JOIN dbo.Empleado AS E 
            ON E.ValorDocumento = T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)')
        INNER JOIN dbo.TipoJornada AS TJ 
            ON TJ.Nombre = T.Item.value('@Jornada', 'VARCHAR(60)')
        INNER JOIN dbo.Semana AS S 
            ON S.FechaInicio = T.Item.value('@InicioSemana', 'DATE')
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.HorarioJornada HJ
            WHERE HJ.idEmpleado = E.id AND HJ.idSemana = S.id
        );


        -- ============================================================
        -- 6. MARCAS DE ASISTENCIA (RELOJ MARCADOR)
        -- ============================================================
        DELETE FROM @TablaMarcasDias;

        INSERT INTO @TablaMarcasDias (ValDoc, Entrada, Salida)
        SELECT 
            T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(30)')
            , T.Item.value('@HoraEntrada', 'DATETIME')
            , T.Item.value('@HoraSalida', 'DATETIME')
        FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/MarcaAsistencia') AS T(Item);

        SET @iMarca = 1;
        SELECT @totalMarcas = ISNULL(MAX(Seq), 0) FROM @TablaMarcasDias;

        WHILE (@iMarca <= @totalMarcas)
        BEGIN
            SELECT @VarDoc = ValDoc, @VarEntrada = Entrada, @VarSalida = Salida
            FROM @TablaMarcasDias WHERE Seq = @iMarca;

            EXEC dbo.spProcesarMarcaAsistencia
                @inValorDocumento = @VarDoc
                , @inHoraEntrada = @VarEntrada
                , @inHoraSalida = @VarSalida
                , @inFechaOperacion = @FechaActual
                , @outResultCode = @ResultCode OUTPUT;

            IF (@ResultCode <> 0)
            BEGIN
                SET @MsgErr = FORMATMESSAGE('Error en marca de %s el %s. Cod: %d',
                    @VarDoc, CONVERT(VARCHAR(10), @FechaActual, 120), @ResultCode);
                RAISERROR(@MsgErr, 16, 1);
            END;

            SET @iMarca = @iMarca + 1;
        END;


        -- ============================================================
        -- 7. CIERRE Y APERTURA DE SEMANA (Solo los Jueves)
        -- ============================================================
        IF (DATEPART(WEEKDAY, @FechaActual) = 5)
        BEGIN
            EXEC dbo.spCierreSemanal
                @FechaActual = @FechaActual
                , @outResultCode = @ResultCode OUTPUT;

            IF (@ResultCode <> 0)
                RAISERROR('Error en cierre semanal en el ETL.', 16, 1);

            EXEC dbo.spAperturaSemana
                @inFechaJueves = @FechaActual
                , @outResultCode = @ResultCode OUTPUT;

            IF (@ResultCode <> 0)
                RAISERROR('Error en apertura semanal en el ETL.', 16, 1);
        END;

        -- Avanzar a la siguiente Fecha de Operación
        SELECT @FechaActual = MIN(Fecha) FROM @TablaFechas WHERE Fecha > @FechaActual;

    END; -- Fin del While principal

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SET @outResultCode = 50008; -- Código general de aborto del ETL

    DECLARE @ErrorNum INT = ERROR_NUMBER();
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSev INT = ERROR_SEVERITY();
    DECLARE @ErrorStat INT = ERROR_STATE();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorProc NVARCHAR(128) = ERROR_PROCEDURE();

    EXEC dbo.spInsertarError
        @InErrorNumber = @ErrorNum
        , @InErrorMessage = @ErrorMsg
        , @InErrorSeverity = @ErrorSev
        , @InErrorState = @ErrorStat
        , @InErrorLine = @ErrorLine
        , @InErrorProcedure = @ErrorProc
        , @outResultCode = @outResultCode OUTPUT;

END CATCH;
END;
GO