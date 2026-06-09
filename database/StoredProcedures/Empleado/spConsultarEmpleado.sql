CREATE OR ALTER PROCEDURE dbo.spConsultarEmpleado
    @inId INT
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
BEGIN TRY

    SET @outResultCode = 0;

    IF NOT EXISTS (SELECT 1 FROM dbo.Empleado AS E WHERE E.id = @inId AND E.Activo = 1)
    BEGIN
        SET @outResultCode = 50012;
        RETURN;
    END;

    SELECT
        E.id AS Id
        , E.Nombre
        , E.ValorDocumento AS ValorDocumentoIdentidad
        , E.CuentaBancaria
        , E.FechaContratacion
        , E.Activo
        , P.Nombre AS NombrePuesto
        , P.id AS IdPuesto
    FROM dbo.Empleado AS E
    INNER JOIN dbo.Puesto AS P ON (P.id = E.idPuesto)
    WHERE E.id = @inId;

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
