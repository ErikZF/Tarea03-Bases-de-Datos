CREATE OR ALTER PROCEDURE dbo.spCargarCatalogosXML
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @outResultCode = 0;

        DECLARE @xmlData XML;
        SELECT @xmlData = CAST(BulkColumn AS XML)
        FROM OPENROWSET(BULK '/scripts/Data/Catalogos.xml', SINGLE_BLOB) AS x;

        BEGIN TRANSACTION;

            -- 1. Cargar tipos de Jornada
            INSERT dbo.TipoJornada
            (
                id
                ,Nombre
                ,HoraInicio
                ,HoraFin
            )
            SELECT
                T.Item.value('@Id', 'INT')
                , T.Item.value('@Nombre', 'VARCHAR(256)')
                , T.Item.value('@HoraInicio', 'TIME(0)')
                , T.Item.value('@HoraFin', 'TIME(0)')
            FROM @xmlData.nodes('/Datos/TiposJornada/TipoJornada')
                AS T(Item);

            -- 2. Cargar Puestos
            INSERT dbo.Puesto
            (
                Nombre
                , SalarioXHora
            )
            SELECT
                T.Item.value('@Nombre', 'VARCHAR(256)')
                , T.Item.value('@SalarioXHora', 'MONEY')
            FROM @xmlData.nodes('/Datos/Puestos/Puesto')
                AS T(Item);

            -- 3. Insertar Feriados
            INSERT dbo.Feriado
            (
                id
                ,Nombre
                ,Fecha
            )
            SELECT
                T.Item.value('@Id', 'INT')
                , T.Item.value('@Nombre', 'VARCHAR(256)')
                , T.Item.value('@Fecha', 'DATE')
            FROM @xmlData.nodes('/Datos/Feriados/Feriado')
                AS T(Item);

            -- 4. Insertar tipos de movimiento
            INSERT dbo.TipoMovimiento
            (
                id
                ,Nombre
                ,Accion
            )
            SELECT
                T.Item.value('@Id', 'INT')
                , T.Item.value('@Nombre', 'VARCHAR(256)')
                , T.Item.value('@Accion', 'VARCHAR(8)')
            FROM @xmlData.nodes('/Datos/TiposMovimiento/TipoMovimiento')
                AS T(Item);

            -- 5. Insertar tipos de deduccion
            INSERT dbo.TipoDeduccion
            (
                id
                ,Nombre
                ,EsObligatoria
                ,EsPorcentual
                ,Valor
                ,idTipoMovimiento
            )
            SELECT
                T.Item.value('@Id', 'INT')
                , T.Item.value('@Nombre', 'VARCHAR(256)')
                , T.Item.value('@EsObligatoria', 'BIT')
                , T.Item.value('@EsPorcentual', 'BIT')
                , T.Item.value('@Valor', 'REAL')
                , TM.id
            FROM @xmlData.nodes('/Datos/TiposDeduccion/TipoDeduccion')
                AS T(Item)
            INNER JOIN dbo.TipoMovimiento AS TM
                ON TM.Nombre = T.Item.value('@TipoMovimiento', 'VARCHAR(256)');

            -- 6. Insertar Usuarios
            INSERT dbo.Usuario
            (
                id
                , Username
                , PasswordHash
                , Tipo
            )
            SELECT
                T.Item.value('@Id', 'INT')
                , T.Item.value('@Username', 'VARCHAR(256)')
                , T.Item.value('@PasswordHash', 'VARCHAR(256)')
                , T.Item.value('@Tipo', 'VARCHAR(256)')
            FROM @xmlData.nodes('/Datos/Usuarios/Usuario')
                AS T(Item);

            -- 7. Insertar Tipo de Evento
            INSERT dbo.TipoEvento
            (
                id
                ,Nombre
            )
            SELECT
                T.Item.value('@Id', 'INT')
                , T.Item.value('@Nombre', 'VARCHAR(256)')
            FROM @xmlData.nodes('/Datos/TiposEvento/TipoEvento')
                AS T(Item);

            -- 8. Insertar codigos de error
            INSERT INTO dbo.Error
            (
                Codigo
                ,Descripcion
            )
            SELECT
                T.item.value('@Codigo', 'VARCHAR(100)')
                , T.item.value('@Descripcion', 'VARCHAR(1024)')
            FROM @xmlData.nodes('/Datos/Error/error')
                AS T(item);

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
             @InErrorNumber    = @ErrorNum
            ,@InErrorMessage   = @ErrorMsg
            ,@InErrorSeverity  = @ErrorSev
            ,@InErrorState     = @ErrorStat
            ,@InErrorLine      = @ErrorLine
            ,@InErrorProcedure = @ErrorProc
            ,@outResultCode    = @outResultCode OUTPUT;
    END CATCH
END;
GO
