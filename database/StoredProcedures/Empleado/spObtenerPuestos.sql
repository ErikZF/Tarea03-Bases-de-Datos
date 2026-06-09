CREATE OR ALTER PROCEDURE dbo.spObtenerPuestos
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
BEGIN TRY

    SET @outResultCode = 0;

    SELECT
        P.id AS Id
        , P.Nombre
    FROM dbo.Puesto AS P
    ORDER BY P.Nombre;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SET @outResultCode = 50008;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrNum INT = ERROR_NUMBER();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrStat INT = ERROR_STATE();
    DECLARE @ErrLine INT = ERROR_LINE();
    DECLARE @ErrProc NVARCHAR(128) = ISNULL(ERROR_PROCEDURE(), '');
    DECLARE @outCode INT = 0;

    EXEC dbo.spInsertarError
        @InErrorNumber = @ErrNum
        , @InErrorMessage = @ErrMsg
        , @InErrorSeverity = @ErrSev
        , @InErrorState = @ErrStat
        , @InErrorLine = @ErrLine
        , @InErrorProcedure = @ErrProc
        , @outResultCode = @outCode OUTPUT;

END CATCH;
END;
GO
