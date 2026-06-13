CREATE OR ALTER PROCEDURE dbo.spConsultarDeduccionesSemanal
    @inIdEmpleado           INT
    ,@inIdPlanillaSemanal   INT
    ,@outResultCode         INT OUTPUT
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON;

    SET @outResultCode = 0;

    DECLARE
        @HorasOrdinarias  DECIMAL(6,2)
        , @HorasExtraNormal DECIMAL(6,2)
        , @HorasExtraDoble  DECIMAL(6,2)
        , @SalarioXHora     DECIMAL(10,2)
        , @NumJuevesMes     INT
        , @FechaInicio      DATE
        ;

    SELECT
        @HorasOrdinarias  = PS.HorasOrdinarias
        , @HorasExtraNormal = PS.HorasExtraNormal
        , @HorasExtraDoble  = PS.HorasExtraDoble
        , @SalarioXHora     = P.SalarioXHora
        , @NumJuevesMes     = M.NumJueves
        , @FechaInicio      = S.FechaInicio
    FROM dbo.PlanillaSemanal AS PS
    INNER JOIN dbo.Empleado AS E ON (E.id = PS.idEmpleado)
    INNER JOIN dbo.Puesto AS P ON (P.id = E.idPuesto)
    INNER JOIN dbo.Semana AS S ON (S.id = PS.idSemana)
    INNER JOIN dbo.Mes AS M ON (M.id = S.idMes)
    WHERE PS.id = @inIdPlanillaSemanal
        AND PS.idEmpleado = @inIdEmpleado;

    SELECT
        TD.Nombre
        , TD.EsPorcentual
        , TD.Valor
        , CAST(
            CASE
                WHEN TD.EsPorcentual = 1 THEN
                    ((@HorasOrdinarias  * @SalarioXHora)
                    + (@HorasExtraNormal * @SalarioXHora * 1.5)
                    + (@HorasExtraDoble  * @SalarioXHora * 2.0)) * TD.Valor
                ELSE
                    DE.MontoFijo / @NumJuevesMes
            END
          AS DECIMAL(12,2)) AS Monto
    FROM dbo.DeduccionEmpleado AS DE
    INNER JOIN dbo.TipoDeduccion AS TD ON (TD.id = DE.idTipoDeduccion)
    WHERE DE.idEmpleado = @inIdEmpleado
        AND @FechaInicio BETWEEN DE.FechaInicio AND DE.FechaFin
    ORDER BY TD.Nombre;

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
END;
GO
