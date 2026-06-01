CREATE PROCEDURE dbo.spCierreSemanal
    @FechaActual DATE
    ,@outResultCode INT OUTPUT
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON;

    DECLARE @IdSemana INT;
    DECLARE @NumJuevesMes INT;

    SELECT 
        @IdSemana = S.id,
        @NumJuevesMes = M.NumJueves
    FROM 
        dbo.Semana AS S
    INNER JOIN dbo.Mes AS M 
        ON S.idMes = M.id
    WHERE @FechaActual BETWEEN S.FechaInicio AND S.FechaFin;

    
    IF (@IdSemana IS NULL)
        RETURN;

    DECLARE @TablaDeduccionesSemanal TABLE 
    (
        idEmpleado              INT
        ,MontoTotalDeducciones   MONEY
        ,SalarioXHora           MONEY
    )
    
    INSERT @TablaDeduccionesSemanal 
    (
        idEmpleado
        ,MontoTotalDeducciones
        ,SalarioXHora
    )
    SELECT 
        DE.idEmpleado
        ,SUM(
            CASE 
                -- tipo deduccion porcentual
                WHEN TD.EsPorcentual = 1 THEN 
                    ((PS.HorasOrdinarias * P.SalarioXHora) + 
                     (PS.HorasExtraNormal * P.SalarioXHora * 1.5) + 
                     (PS.HorasExtraDoble * P.SalarioXHora * 2.0)) * (TD.Valor / 100.0)
                
                -- tipo deduccion fija
                ELSE 
                    (DE.MontoFijo / @NumJuevesMes)
            END
        )
        ,P.SalarioXHora

    FROM dbo.DeduccionEmpleado AS DE
    INNER JOIN dbo.TipoDeduccion AS TD 
        ON DE.idTipoDeduccion = TD.id
    INNER JOIN dbo.PlanillaSemanal AS PS 
        ON DE.idEmpleado = PS.idEmpleado AND PS.idSemana = @IdSemana
    INNER JOIN dbo.Empleado AS E 
        ON PS.idEmpleado = E.id
    INNER JOIN dbo.Puesto AS P 
        ON E.idPuesto = P.id
    WHERE 
        @FechaActual BETWEEN DE.FechaInicio AND DE.FechaFin
    GROUP BY 
        DE.idEmpleado, P.SalarioXHORA




    BEGIN TRANSACTION
    -- actualiza valores de la planilla semanal
    UPDATE PS WITH(ROWLOCK)
    SET 
        -- Cálculo del Salario Bruto según las horas procesadas 
        PS.SalarioBruto = (PS.HorasOrdinarias * P.SalarioXHora) + 
                          (PS.HorasExtraNormal * P.SalarioXHora * 1.5) + 
                          (PS.HorasExtraDoble * P.SalarioXHora * 2.0),

        -- Asignación de deducciones calculadas (si no tiene, se pone 0)
        PS.TotalDeducciones = ISNULL(TD.MontoTotalDeducciones, 0),

        -- Salario Neto Final
        PS.SalarioNeto = ((PS.HorasOrdinarias * P.SalarioXHora) + 
                          (PS.HorasExtraNormal * P.SalarioXHora * 1.5) + 
                          (PS.HorasExtraDoble * P.SalarioXHora * 2.0)) - ISNULL(TD.MontoTotalDeducciones, 0)
    
    FROM dbo.PlanillaSemanal AS PS
    
    INNER JOIN dbo.Empleado E 
        ON PS.idEmpleado = E.id

    INNER JOIN dbo.Puesto P 
        ON E.idPuesto = P.id

    LEFT JOIN @TablaDeduccionesSemanal TD 
        ON PS.idEmpleado = TD.idEmpleado

    WHERE PS.idSemana = @IdSemana;
    
    COMMIT TRANSACTION
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