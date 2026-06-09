CREATE PROCEDURE dbo.spEliminarEmpleado
    @inIdEmpleado           INT
    , @inIdUsuario          INT
    , @inIP                 VARCHAR(50)
    , @outResultCode        INT OUTPUT
AS
BEGIN
BEGIN TRY
SET NOCOUNT ON

    SET @outResultCode = 0

    DECLARE @ParametrosJSON VARCHAR(500) = NULL
    DECLARE @_bitacoraRC    INT          = 0
    DECLARE @_desc          VARCHAR(500) = NULL

    IF NOT EXISTS (
        SELECT 1 FROM dbo.Empleado AS E WHERE E.id = @inIdEmpleado
    )
        SET @outResultCode = 50012

    ELSE IF EXISTS (
        SELECT 1 FROM dbo.Empleado AS E
        WHERE E.id = @inIdEmpleado AND E.Activo = 0
    )
        SET @outResultCode = 50012

    SELECT
        @ParametrosJSON = CONCAT(
            '{"ValorDocumento":"', E.ValorDocumento,
            '","Nombre":"', E.Nombre,
            '","IdPuesto":', E.idPuesto,
            ',"CuentaBancaria":"', E.CuentaBancaria, '"}'
        )
    FROM dbo.Empleado AS E
    WHERE E.id = @inIdEmpleado

    IF (@outResultCode <> 0)
    BEGIN
        SET @_desc = CONCAT('Fallo al eliminar empleado. Cod:', @outResultCode, ' ', @ParametrosJSON);
        EXEC dbo.spInsertarBitacoraEvento
            @inIdTipoEvento  = 9
            , @inIdUsuario   = @inIdUsuario
            , @inIP          = @inIP
            , @inDescripcion = @_desc
            , @outResultCode = @_bitacoraRC OUTPUT;
        RETURN
    END

    BEGIN TRANSACTION
    UPDATE E WITH(ROWLOCK)
    SET E.Activo = 0
    FROM dbo.Empleado AS E
    WHERE E.id = @inIdEmpleado

    SET @_desc = CONCAT('Empleado eliminado: ', @ParametrosJSON);
    EXEC dbo.spInsertarBitacoraEvento
        @inIdTipoEvento  = 10
        , @inIdUsuario   = @inIdUsuario
        , @inIP          = @inIP
        , @inDescripcion = @_desc
        , @outResultCode = @_bitacoraRC OUTPUT;

    COMMIT TRANSACTION

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SET @outResultCode = 50008;

    DECLARE @ErrorNum  INT            = ERROR_NUMBER();
    DECLARE @ErrorMsg  NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSev  INT            = ERROR_SEVERITY();
    DECLARE @ErrorStat INT            = ERROR_STATE();
    DECLARE @ErrorLine INT            = ERROR_LINE();
    DECLARE @ErrorProc NVARCHAR(128)  = ERROR_PROCEDURE();

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
