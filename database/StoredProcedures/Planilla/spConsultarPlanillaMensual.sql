CREATE OR ALTER PROCEDURE dbo.spConsultarPlanillaMensual
    @inIdEmpleado    INT
    , @outResultCode INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    SELECT
        PM.id
        , M.FechaInicio
        , M.FechaFin
        , PM.SalarioBruto
        , PM.TotalDeducciones
        , PM.SalarioNeto
    FROM dbo.PlanillaMensual AS PM
    INNER JOIN dbo.Mes AS M ON (M.id = PM.idMes)
    WHERE (PM.idEmpleado = @inIdEmpleado)
    ORDER BY M.FechaInicio DESC;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE
        @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE()
        , @ErrNum INT = ERROR_NUMBER()
        , @ErrSev INT = ERROR_SEVERITY()
        , @ErrStat INT = ERROR_State()
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