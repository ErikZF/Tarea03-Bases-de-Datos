CREATE TRIGGER triggerAsociarEmpleadoDeducciones
ON Empleado
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT dbo.DeduccionEmpleado
     (
        IdEmpleado
        ,IdTipoDeduccion
        ,MontoFijo
        ,FechaInicio
        ,FechaFin
    )
    
    SELECT 
        E.Id                   
        ,TD.Id                  
        ,TD.Valor * 100
        ,E.FechaContratacion
        ,'9999-12-31'

    FROM inserted E
    CROSS JOIN TipoDeDeduccion TD
    WHERE td.Obligatorio = 1; 
END;