CREATE PROCEDURE dbo.spETLCargaOperacionEmpleado
    @ParametroXML XML
    ,@outResultCode INT OUTPUT
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON;

    SET @outResultCode = 0

    DECLARE @FechaActual DATE;
    

    DECLARE @TablaFechas TABLE (
            Fecha DATE PRIMARY KEY
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

            ,idDepartamento
            ,idTipoDocumento
            ,idUsuario

            ,ValorDocumento
            ,Nombre
            ,CuentaBancaria

            ,FechaContratacion
            ,Activo
        )
        SELECT 
            T.Item.value('@IdPuesto', 'INT')

            ,T.Item.value('@IdDepartamento', 'INT')
            ,T.Item.value('@IdTipoDocumento', 'INT')
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



        -- marcas de asistencia



        -- cierre de semana

        IF DATEPART(WEEKDAY, @FechaActual) = 5 
            BEGIN
                DECLARE @ResultCodeCierre INT = 0;
                
                EXEC dbo.spCierreSemanal 
                    @FechaActual      = @FechaActual, 
                    @outResultCode    = @ResultCodeCierre OUTPUT;
                    
                IF @ResultCodeCierre <> 0
                BEGIN
                    RAISERROR('Error ejecutando el cierre semanal en el ETL.', 16, 1);
                END
            END;





        -- apertura de semana


        --Pasar a la siguiente fecha
        SELECT 
            @FechaActual = MIN(TF.Fecha) 
        FROM @TablaFechas AS TF
            WHERE TF.Fecha > @FechaActual
    END -- fin del while
    

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


