CREATE PROCEDURE dbo.spETLCargaOperacionEmpleado
    @ParametroXML XML
    ,@outResultCode INT OUTPUT
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON;

    SET @outResultCode = 0

    DECLARE @FechaActual DATE;

    DECLARE @IteradorMarcas INT;
    DECLARE @TotalMarcasDia INT;
    DECLARE @VarDoc VARCHAR(30);
    DECLARE @VarEntrada DATETIME;
    DECLARE @VarSalida DATETIME;
    DECLARE @ResultCodeMarca INT;

    DECLARE @ResultCodeCierre INT;

    DECLARE @ResultCodeApertura INT;

    DECLARE @TablaFechas TABLE (
            Fecha DATE PRIMARY KEY
        );

    DECLARE @TablaMarcasDia TABLE (
        Secuencial INT IDENTITY(1,1) PRIMARY KEY
        , DocumentoIdentidad VARCHAR(20)
        , HoraEntrada DATETIME
        , HoraSalida DATETIME
    );



    INSERT @TablaFechas (
        Fecha
    )
    SELECT
        DISTINCT T.Item.value('@Fecha', 'DATE')
    FROM 
        @ParametroXML.nodes('/Operacion/FechaOperacion')
        AS T(Item)

    SELECT
        @FechaActual = MIN(TF.Fecha)
    FROM
        @TablaFechas AS TF




    BEGIN TRANSACTION
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
        FROM @ParametroXML.nodes('/Operacion/FechaOperacion[@Fecha=sql:variable("@FechaActual")]/MarcaAsistencia') AS T(Item);

        -- 3. Ciclo interno para procesar una por una las marcas de este día
        SET @IteradorMarcas = 1; 
        SET @TotalMarcasDia = ISNULL((SELECT MAX(Secuencial) FROM @TablaMarcasDia), 0);

        WHILE (@IteradorMarcas <= @TotalMarcasDia)
        BEGIN
            -- Extraer los datos de la marca actual en el sub-ciclo
            SELECT 
                @VarDoc = DocumentoIdentidad
                , @VarEntrada = HoraEntrada
                , @VarSalida = HoraSalida
            FROM @TablaMarcasDia
            WHERE Secuencial = @IteradorMarcas;

            -- Ejecutar el SP del compañero para esta marca específica
            EXEC dbo.spProcesarMarcaAsistencia
                @inValorDocumento = @VarDoc
                , @inHoraEntrada = @VarEntrada
                , @inHoraSalida = @VarSalida
                , @inFechaOperacion = @FechaActual
                , @outResultCode = @ResultCodeMarca OUTPUT;

            -- Control de flujo: Si la marca falló, disparamos un error para activar tu CATCH externo
            IF (@ResultCodeMarca <> 0)
            BEGIN
                DECLARE @MsgErrorMarca NVARCHAR(250);
                SET @MsgErrorMarca = FORMATMESSAGE('Error al procesar la marca del empleado %s en la fecha %s. Código de error interno: %d', 
                                                   @VarDoc, CONVERT(VARCHAR(10), @FechaActual, 120), @ResultCodeMarca);
                RAISERROR(@MsgErrorMarca, 16, 1);
            END;

            SET @IteradorMarcas = @IteradorMarcas + 1;
        END;

        -- cierre de semana

        IF DATEPART(WEEKDAY, @FechaActual) = 5 
            BEGIN

                EXEC dbo.spCierreSemanal 
                    @FechaActual      = @FechaActual, 
                    @outResultCode    = @ResultCodeCierre OUTPUT;

                IF @ResultCodeCierre <> 0
                BEGIN
                    RAISERROR('Error ejecutando el cierre semanal en el ETL.', 16, 1);
                END
            END;

        -- apertura de semana
        IF DATEPART(WEEKDAY, @FechaActual) = 5
            BEGIN

                EXEC dbo.spAperturaSemana 
                    @inFechaJueves = @FechaActual
                    ,@outResultCode = @ResultCodeApertura OUTPUT

                IF @ResultCodeApertura <> 0
                BEGIN
                    RAISERROR('Error ejecutando la apertura semanal en el ETL.', 16, 1);
                END

            END


        --Pasar a la siguiente fecha
        SELECT 
            @FechaActual = MIN(TF.Fecha) 
        FROM @TablaFechas AS TF
            WHERE TF.Fecha > @FechaActual
    END -- fin del while



    UPDATE DM 
    SET 
        DM.MontoTotal = SemanalDeduc.MontoMes
    FROM 
        dbo.DeduccionXMes AS DM
    INNER JOIN dbo.PlanillaMensual AS PM 
        ON DM.idPlanillaMensual = PM.id

    INNER JOIN (
        SELECT 
            PS.idEmpleado
            ,S.idMes
            ,TD.id AS idTipoDeduccion
            ,SUM(
                CASE 
                    WHEN TD.EsPorcentual = 1 THEN 
                        PS.SalarioBruto * (TD.Valor / 100.0)
                    ELSE 
                        (DE.MontoFijo / M.NumJueves)
                END
            ) AS MontoMes

        FROM 
            dbo.PlanillaSemanal AS PS
        INNER JOIN dbo.Semana AS S 
            ON PS.idSemana = S.id
        INNER JOIN dbo.Mes AS M 
            ON S.idMes = M.id
        INNER JOIN dbo.DeduccionEmpleado AS 
            DE ON PS.idEmpleado = DE.idEmpleado
        INNER JOIN dbo.TipoDeduccion AS TD ON 
            DE.idTipoDeduccion = TD.id
        WHERE 
            S.FechaInicio BETWEEN DE.FechaInicio AND DE.FechaFin
        GROUP BY PS.idEmpleado, S.idMes, TD.id

    ) AS SemanalDeduc 
        ON PM.idEmpleado = SemanalDeduc.idEmpleado 
        AND PM.idMes = SemanalDeduc.idMes 
        AND DM.idTipoDeduccion = SemanalDeduc.idTipoDeduccion;


    -- Sumar los salarios semanales para actualizar los totales mensuales
    UPDATE PM
    SET 
        PM.SalarioBruto = Totales.TotalBruto,
        PM.TotalDeducciones = Totales.TotalDeducciones,
        PM.SalarioNeto = Totales.TotalBruto - Totales.TotalDeducciones
    FROM 
        dbo.PlanillaMensual AS PM
    INNER JOIN (
        SELECT 
            PS.idEmpleado
            ,S.idMes
            ,SUM(PS.SalarioBruto) AS TotalBruto
            ,SUM(PS.TotalDeducciones) AS TotalDeducciones
        FROM 
            dbo.PlanillaSemanal AS PS
        INNER JOIN dbo.Semana AS S 
            ON PS.idSemana = S.id
        GROUP BY PS.idEmpleado, S.idMes
    ) AS Totales 
        ON PM.idEmpleado = Totales.idEmpleado 
        AND PM.idMes = Totales.idMes;



    COMMIT TRANSACTION
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
             @InErrorNumber    = @ErrorNum
            ,@InErrorMessage   = @ErrorMsg
            ,@InErrorSeverity  = @ErrorSev
            ,@InErrorState     = @ErrorStat
            ,@InErrorLine      = @ErrorLine
            ,@InErrorProcedure = @ErrorProc
            ,@outResultCode    = @outResultCode OUTPUT;

END CATCH
END;