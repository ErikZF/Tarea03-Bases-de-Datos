CREATE PROCEDURE dbo.spEliminarEmpleado
    @inIdEmpleado           INT
    , @inIdUsuario          INT
    , @inIP                 VARCHAR (50)
    , @outResultCode        INT OUTPUT
AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
    
    SET @outResultCode = 0

    DECLARE @ParametrosJSON VARCHAR(1000) = NULL

     -- Validar que de hecho exista un empleado con ese id
    IF NOT EXISTS (
        SELECT
            1
        FROM
            dbo.Empleado AS E
        WHERE 
            E.id = @inIdEmpleado
    )
        SET @outResultCode = 50012 -- No existe un empleado con ese id


     -- Validar que ese empleado no se haya eliminado ya
    ELSE IF EXISTS (
        SELECT
            1
        FROM
            dbo.Empleado AS E
        WHERE 
            E.id = @inIdEmpleado
            AND E.Activo = 0
    )
        SET @outResultCode = 50013 -- Empleado ya fue eliminado


    -- obtener datos del empleado para la bitacora 
    SELECT 
        @ParametrosJSON = CONCAT(
                '{"ValorDocumento":"', E.ValorDocumento, 
                '","Nombre":"', E.Nombre, 
                '","IdPuesto":', E.idPuesto, 
                ',"IdDepartamento":', E.IdDepartamento, 
                ',"CuentaBancaria":"', E.CuentaBancaria, '"}'
            )
    FROM 
        dbo.Empleado AS E
    WHERE
        E.id = @inIdEmpleado


    -- en caso de que haya fallado el SP en alguna validacion
    IF (@outResultCode <> 0)
    BEGIN

        INSERT INTO dbo.BitacoraEvento 
        (
            IdTipoEvento
            ,idUsuario
            ,FechaHora
            ,Descripcion
            ,IP
        )
        VALUES 
        (
            7   -- TipoEvento: update no exitoso
            ,@inIdUsuario
            ,GETUTCDATE()
            ,CONCAT(
                'Fallo al eliminar empleado, Codigo de Error:'
                ,@outResultCode
                ,' Datos: '
                ,@ParametrosJSON)
            ,@inIP
        )

        RETURN
    END


    BEGIN TRANSACTION
    UPDATE E WITH(ROWLOCK)
    SET 
        E.Activo = 0
    FROM
        dbo.Empleado AS E
    WHERE 
        E.id = @inIdEmpleado
    

    INSERT INTO dbo.BitacoraEvento (
        idTipoEvento
        ,idUsuario
        ,Descripcion
        ,FechaHora
        ,IP
    )
    VALUES(
        10 -- TipoEvento: Borrado Exitoso
        ,@inIdUsuario
        ,@ParametrosJSON
        ,GETUTCDATE()
        ,@inIP
    )

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
END

