CREATE OR ALTER PROCEDURE dbo.spListarEmpleados
    @inFiltro VARCHAR(100)
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode =0;

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
    INNER JOIN dbo.Usuario AS U ON (U.id = E.idUsuario)
    WHERE (E.Activo = 1)
        AND (
            (@inFiltro = '')
            OR (E.Nombre LIKE '%' + @inFiltro + '%')
        )
    ORDER BY E.Nombre;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE
        @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE()
        , @ErrNum INT = ERROR_NUMBER()
        , @ErrSev INT = ERROR_SEVERITY()
        , @ErrStat INT = ERROR_STATE()
        , @ErrLine INT = ERROR_LINE()
        , @ErrProc NVARCHAR(128) = ISNULL(ERROR_PROCEDURE(), '')
        , @outCode INT = 0
        ;

    SET @outResultCode = 50001;

    EXEC dbo.spInsertarError
        @InErrorNumber = @ErrNum
        , @InErrorMessage = @ErrMsg
        , @InErrorSeverity = @ErrSev
        , @InErrorState = @ErrStat
        , @InErrorLine = @ErrLine
        , @InErrorProcedure = @ErrProc
        , @outResultCode = @outCode OUTPUT
        ;

END CATCH;

SET NOCOUNT OFF;
END;
GO  