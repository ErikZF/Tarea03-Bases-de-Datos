CREATE OR ALTER PROCEDURE dbo.spETLCargaOperacionEmpleado
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
BEGIN TRY

    SET @outResultCode = 0;

    DECLARE @xmlData XML;
    SELECT @xmlData = CAST(BulkColumn AS XML)
    FROM OPENROWSET(BULK '/scripts/Data/Operaciones.xml', SINGLE_BLOB) AS x;

    DECLARE @FechaActual DATE;
    DECLARE @ResultCode INT = 0;

    -- Variables loop empleados
    DECLARE @EmpDoc VARCHAR(20);
    DECLARE @EmpNombre VARCHAR(150);
    DECLARE @EmpPuesto VARCHAR(100);
    DECLARE @EmpCuenta VARCHAR(30);
    DECLARE @EmpFechaC DATE;
    DECLARE @EmpIdPuesto INT;
    DECLARE @EmpIdUsuario INT;
    DECLARE @iEmp INT;
    DECLARE @totalEmp INT;

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

    DECLARE @TablaEmpleados TABLE (
        Seq INT IDENTITY(1,1) PRIMARY KEY
        , ValDoc VARCHAR(20)
        , Nombre VARCHAR(150)
        , Puesto VARCHAR(100)
        , Cuenta VARCHAR(30)
        , FechaC DATE
    );

    DECLARE @TablaMarcas TABLE (
        Seq INT IDENTITY(1,1) PRIMARY KEY
        , ValDoc VARCHAR(20)
        , Entrada DATETIME
        , Salida DATETIME
    );

    INSERT @TablaFechas (Fecha)
    SELECT DISTINCT T.Item.value('@Fecha', 'DATE')
    FROM @xmlData.nodes('/Operaciones/FechaOperacion') AS T(Item);

    SELECT @FechaActual = MIN(Fecha) FROM @TablaFechas;

    BEGIN TRANSACTION;

    WHILE (@FechaActual IS NOT NULL)
    BEGIN -- inicio del while

        --Insertar empleados de esta fecha
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
            T.Item.value('@IdPuesto', 'INT')
            ,U.id

            ,T.Item.value('@ValorTipoDocumento', 'VARCHAR(64)')
            ,T.Item.value('@Nombre', 'VARCHAR(256)')
            ,T.Item.value('@CuentaBancaria', 'VARCHAR(256)')

            ,@FechaActual
            ,1 -- activo
        FROM 
            @ParametroXML.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/NuevosEmpleados/NuevoEmpleado') AS T(Item)
        INNER JOIN dbo.Usuario AS U
            ON T.Item.value('@Usuario', 'VARCHAR(256)') = U.Username


        -- --Borrar empleados de esta fecha
        UPDATE E WITH(ROWLOCK) 
        SET        
            E.Activo = 0
        FROM 
            dbo.Empleado E
        INNER JOIN (
            SELECT 
                T.Item.value('@ValorTipoDocumento', 'VARCHAR(64)') AS DocumentoIdentidad
            FROM 
                @ParametroXML.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/EliminarEmpleados/EliminarEmpleado') 
                AS T(Item)
        ) AS XML_Eliminar 
            ON E.ValorDocumento = XML_Eliminar.DocumentoIdentidad


        -- asociar empleados con deducciones NO obligatorias
        INSERT dbo.DeduccionEmpleado
        (
            idEmpleado
            ,idTipoDeduccion
            ,MontoFijo
            ,FechaInicio
            ,FechaFin
        )
        SELECT 
            E.Id
            ,T.Item.value('@IdTipoDeduccion', 'INT')
            ,T.Item.value('@Monto', 'REAL')
            ,@FechaActual
            ,'9999-12-31' -- Indefinida hasta que venga un nodo de desasociación

        FROM @ParametroXML.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') 
            AS T(Item)

        INNER JOIN dbo.Empleado AS E 
            ON E.ValorDocumento = T.Item.value('@ValorTipoDocumento', 'VARCHAR(64)')



        --  desasociar empleados con deducciones (poner ficha fin = hoy)
        UPDATE DE WITH(ROWLOCK)
        SET 
            DE.FechaFin = @FechaActual 
        FROM 
            dbo.DeduccionEmpleado AS DE
            
        INNER JOIN dbo.Empleado AS E 
            ON DE.idEmpleado = E.id
        INNER JOIN @ParametroXML.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') AS T(Item)
            ON E.ValorDocumento = T.Item.value('@ValorTipoDocumento', 'VARCHAR(64)')
            AND DE.IdTipoDeduccion = T.Item.value('@IdTipoDeduccion', 'INT')
        
        WHERE DE.FechaFin >= '9999-12-31'; 


        -- asignacion de jornadas de esta fecha
        INSERT dbo.HorarioJornada
        (
            idEmpleado
            ,idSemana
            ,idTipoJornada
        )
        SELECT 
            E.id   
            ,S.id 
            ,TJ.id 
        FROM 
            @ParametroXML.nodes('/Operacion/FechaOperacion/AsignarJornada') AS T(Item) 
        INNER JOIN dbo.Empleado AS E 
            ON E.ValorDocumento = T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(30)')
        INNER JOIN dbo.TipoJornada AS TJ
            ON TJ.Nombre = T.Item.value('@Jornada', 'VARCHAR(256)')
        INNER JOIN dbo.Semana AS S
            ON S.FechaInicio = T.Item.value('@InicioSemana', 'DATE')
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.HorarioJornada HJ 
            WHERE HJ.idEmpleado = E.id AND HJ.idSemana = S.id
        );


        -- marcas de asistencia

        DELETE FROM @TablaMarcasDia;

        INSERT INTO @TablaMarcasDia 
        (
            DocumentoIdentidad
            ,HoraEntrada
            ,HoraSalida
        )
        SELECT 
            T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(30)')
            , T.Item.value('@HoraEntrada', 'DATETIME')
            , T.Item.value('@HoraSalida', 'DATETIME')
        FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/MarcaAsistencia') AS T(Item);

        SET @iMarca = 1;
        SELECT @totalMarcas = ISNULL(MAX(Seq), 0) FROM @TablaMarcas;

        WHILE (@iMarca <= @totalMarcas)
        BEGIN
            SELECT @VarDoc = ValDoc, @VarEntrada = Entrada, @VarSalida = Salida
            FROM @TablaMarcas WHERE Seq = @iMarca;

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
        -- 3. CIERRE Y APERTURA DE SEMANA (solo jueves = dia 5)
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

        -- ============================================================
        -- 4. ASIGNAR JORNADAS (despues de apertura para que exista la semana nueva)
        -- ============================================================
        INSERT dbo.HorarioJornada (idEmpleado, idSemana, idTipoJornada)
        SELECT
            E.id
            , S.id
            , TJ.id
        FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/AsignarJornada') AS T(Item)
        INNER JOIN dbo.Empleado AS E ON E.ValorDocumento = T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)')
        INNER JOIN dbo.TipoJornada AS TJ ON TJ.Nombre = T.Item.value('@Jornada', 'VARCHAR(60)')
        INNER JOIN dbo.Semana AS S ON S.FechaInicio = T.Item.value('@InicioSemana', 'DATE')
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.HorarioJornada HJ
            WHERE HJ.idEmpleado = E.id AND HJ.idSemana = S.id
        );

        -- ============================================================
        -- 5. ASOCIAR DEDUCCIONES NO OBLIGATORIAS
        -- ============================================================
        INSERT dbo.DeduccionEmpleado (idEmpleado, idTipoDeduccion, MontoFijo, FechaInicio, FechaFin)
        SELECT
            E.id
            , TD.id
            , T.Item.value('@MontoFijo', 'DECIMAL(10,2)')
            , @FechaActual
            , '9999-12-31'
        FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/AsociaEmpleadoConDeduccion') AS T(Item)
        INNER JOIN dbo.Empleado AS E ON E.ValorDocumento = T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)')
        INNER JOIN dbo.TipoDeduccion AS TD ON TD.Nombre = T.Item.value('@TipoDeduccion', 'VARCHAR(100)');

        -- ============================================================
        -- 6. DESASOCIAR DEDUCCIONES (cerrar vigencia con fecha actual)
        -- ============================================================
        UPDATE DE WITH(ROWLOCK)
        SET DE.FechaFin = @FechaActual
        FROM dbo.DeduccionEmpleado AS DE
        INNER JOIN dbo.Empleado AS E ON DE.idEmpleado = E.id
        INNER JOIN (
            SELECT
                T.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)') AS ValDoc
                , TD.id AS idTipoDeduccion
            FROM @xmlData.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/DesasociaEmpleadoConDeduccion') AS T(Item)
            INNER JOIN dbo.TipoDeduccion AS TD ON TD.Nombre = T.Item.value('@TipoDeduccion', 'VARCHAR(100)')
        ) AS Desasoc ON E.ValorDocumento = Desasoc.ValDoc
                    AND DE.idTipoDeduccion = Desasoc.idTipoDeduccion
        WHERE DE.FechaFin >= '9999-12-31';

        -- Avanzar a la siguiente fecha
        SELECT @FechaActual = MIN(Fecha) FROM @TablaFechas WHERE Fecha > @FechaActual;

    END; -- fin while

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SET @outResultCode = 50008;

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
