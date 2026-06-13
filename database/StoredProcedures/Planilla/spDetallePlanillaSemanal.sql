CREATE OR ALTER PROCEDURE dbo.spDetallePlanillaSemanal
    @inIdPlanillaSemanal INT
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    SELECT
        MA.Fecha
        , MA.HoraEntrada
        , MA.HoraSalida
        , ISNULL(SUM(CASE WHEN TM.id = 1 THEN MP.Monto ELSE 0 END), 0) AS MontoOrdinario
        , CAST(ISNULL(SUM(CASE WHEN TM.id = 1 THEN MP.Monto ELSE 0 END), 0) / NULLIF(P.SalarioXHora, 0) AS INT) AS HorasOrdinarias
        , ISNULL(SUM(CASE WHEN TM.id = 2 THEN MP.Monto ELSE 0 END), 0) AS MontoExtra
        , CAST(ISNULL(SUM(CASE WHEN TM.id = 2 THEN MP.Monto ELSE 0 END), 0) / NULLIF(P.SalarioXHora * 1.5, 0) AS INT) AS HorasExtra
        , ISNULL(SUM(CASE WHEN TM.id = 3 THEN MP.Monto ELSE 0 END), 0) AS MontoDobles
        , CAST(ISNULL(SUM(CASE WHEN TM.id = 3 THEN MP.Monto ELSE 0 END), 0) / NULLIF(P.SalarioXHora * 2.0, 0) AS INT) AS HorasDobles
    FROM dbo.Comprobante AS C
    INNER JOIN dbo.ComprobanteHora AS CH ON (CH.idComprobante = C.id)
    INNER JOIN dbo.MarcaAsistencia AS MA ON (MA.id = CH.idMarcaAsistencia)
    INNER JOIN dbo.MovPlanilla AS MP ON (MP.idComprobante = C.id)
    INNER JOIN dbo.TipoMovimiento AS TM ON (TM.id = MP.idTipoMovimiento)
    INNER JOIN dbo.Empleado AS E ON (E.id = MA.idEmpleado)
    INNER JOIN dbo.Puesto AS P ON (P.id = E.idPuesto)
    WHERE (C.idPlanillaSemanal = @inIdPlanillaSemanal)
        AND (C.Tipo = 'H')
    GROUP BY MA.Fecha, MA.HoraEntrada, MA.HoraSalida, P.SalarioXHora
    ORDER BY MA.Fecha, MA.HoraEntrada;

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
