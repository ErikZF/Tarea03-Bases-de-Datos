CREATE OR ALTER PROCEDURE dbo.spDetallePlanillaMensual
    @inIdEmpleado         INT
    ,@inIdPlanillaMensual INT
    ,@outResultCode       INT OUTPUT
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY

    SET @outResultCode = 0
    
    SELECT
        TD.Nombre                           -- Nombre del tipo de deducción
        ,SUM(DM.MontoTotal) AS Monto   
        ,TD.EsPorcentual
        ,TD.Valor
    FROM
        dbo.PlanillaMensual AS PM
    INNER JOIN dbo.DeduccionXMes AS DM
        ON DM.idPlanillaMensual = PM.id
    INNER JOIN dbo.TipoDeduccion AS TD
        ON DM.idTipoDeduccion = TD.id
    WHERE  
        PM.id = @inIdPlanillaMensual
        AND PM.idEmpleado = @inIdEmpleado
    GROUP BY 
        TD.Nombre, 
        TD.EsPorcentual, 
        TD.Valor 


        
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