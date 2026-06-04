CREATE PROCEDURE dbo.spConsultarDeduccionesSemanal
    @inIdEmpleado           INT
    ,@inIdPlanillaSemanal   INT 
    ,@outResultCode         INT OUTPUT
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON;

    SET @outResultCode = 0
   
    SELECT 
        TD.Nombre       -- el nombre de lo que se le rebajo
        , MP.Monto      -- cuanto se le rebajo
        , TD.EsPorcentual -- Lo que se rebajo fue un porcentaje?
        , TD.Valor      -- El valor (porcentaje o fijo) de lo que sea que se le bajo
    FROM 
        dbo.PlanillaSemanal AS PS
    INNER JOIN dbo.Comprobante AS C 
        ON C.idPlanillaSemanal = PS.id
    INNER JOIN dbo.MovPlanilla AS MP 
        ON MP.idComprobante = C.id
    INNER JOIN dbo.TipoDeduccion AS TD 
        ON TD.idTipoMovimiento = MP.idTipoMovimiento 
    WHERE 
        PS.idEmpleado = @inIdEmpleado
        AND PS.id = @inIdPlanillaSemanal;
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