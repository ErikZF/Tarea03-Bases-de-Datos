CREATE OR ALTER PROCEDURE dbo.spDetallePlanillaSemanal
    @inIdPlanillaSemanal INT
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    -- Detalle por dia, hora entrada, salida y movimientos generados
    SELECT
        MA.Fecha
        , MA.HoraEntrada
        , MA.HoraSalida
        , TM.Nombre AS TipoMovimiento
        , TM.Accion
        , MP.Monto
        , MP.NuevoSaldo
    FROM dbo.Comprobante AS C
    INNER JOIN dbo.ComprobanteHora AS CH ON (CH.idComprobante = C.id)
    INNER JOIN dbo.MarcaAsistencia AS MA ON (MA.id = CH.idMarcaAsistencia)
    INNER JOIN dbo.MovPlanilla AS MP ON (MP.idComprobante = C.id)
    INNER JOIN dbo.TipoMovimiento AS TM ON (TM.id = MP.idTipoMovimiento)
    WHERE (C.idPlanillaSemanal = @inIdPlanillaSemanal)
        AND (C.Tipo = 'H')
    ORDER BY MA.Fecha, MA.HoraEntrada, TM.id;

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