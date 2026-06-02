CREATE PROCEDURE dbo.spConsultarPlanillaSemanal
    @inIdEmpleado      INT
    , @inCantSemanas   INT
    , @outResultCode   INT OUTPUT
AS
BEGIN
BEGIN TRY
    
    SET NOCOUNT ON;
    SET @outResultCode = 0;

    
    IF NOT EXISTS (
        SELECT 
            1 
        FROM 
            dbo.Empleado AS E 
        WHERE 
            E.id = @inIdEmpleado
    )
    BEGIN
        SET @outResultCode = 50001 -- Empleado no encontrado
        RETURN
    END


    SELECT TOP (@inCantSemanas)
        E.Nombre 
        ,S.FechaInicio 
        ,S.FechaFin
        ,PS.SalarioBruto
        ,PS.TotalDeducciones
        ,PS.SalarioNeto
        ,PS.HorasOrdinarias
        ,PS.HorasExtraNormal
        ,PS.HorasExtraDoble
    FROM
        dbo.PlanillaSemanal AS PS
    INNER JOIN dbo.Semana AS S
        ON PS.idSemana = S.id
    INNER JOIN dbo.Empleado AS E
        ON PS.idEmpleado = E.id
    WHERE
        PS.idEmpleado = @inIdEmpleado
    ORDER BY
        S.FechaInicio DESC; -- semanas mas recientes primero

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        

    INSERT INTO dbo.DBError
    (
        UserName
        ,Number
        ,State
        ,Severity
        ,Line
        ,[Procedure]
        ,Message
    )
    VALUES
    (
        SUSER_SNAME()
        , ERROR_NUMBER()
        , ERROR_STATE()
        , ERROR_SEVERITY()
        , ERROR_LINE()
        , ISNULL(ERROR_PROCEDURE(), 'spConsultarPlanillaSemanal')
        , ERROR_MESSAGE()
    )
    
    SET @outResultCode = 50005; 

END CATCH
END
GO