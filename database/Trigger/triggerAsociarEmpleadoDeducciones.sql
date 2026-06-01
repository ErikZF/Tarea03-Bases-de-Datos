-- triggerAsociarEmpleadoDeducciones.sql
-- Asocia automaticamente las deducciones obligatorias al insertar un empleado

CREATE OR ALTER TRIGGER dbo.triggerAsociarEmpleadoDeducciones
ON dbo.Empleado
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        INSERT INTO dbo.DeduccionEmpleado (
            idEmpleado
            , idTipoDeduccion
            , MontoFijo
            , FechaInicio
            , FechaFin
        )
        SELECT
            E.id
            , TD.id
            , 0
            , E.FechaContratacion
            , '9999-12-31'
        FROM inserted E
        CROSS JOIN dbo.TipoDeduccion TD
        WHERE (TD.EsObligatoria = 1);

    END TRY
    BEGIN CATCH

        DECLARE
            @ErrMsg  NVARCHAR(4000) = ERROR_MESSAGE()
            , @ErrNum  INT          = ERROR_NUMBER()
            , @ErrSev  INT          = ERROR_SEVERITY()
            , @ErrStat INT          = ERROR_STATE()
            , @ErrLine INT          = ERROR_LINE()
            , @ErrProc NVARCHAR(128) = ISNULL(ERROR_PROCEDURE(), '')
            , @outCode INT          = 0
            ;

        EXEC dbo.spInsertarError
            @InErrorNumber    = @ErrNum
            , @InErrorMessage   = @ErrMsg
            , @InErrorSeverity  = @ErrSev
            , @InErrorState     = @ErrStat
            , @InErrorLine      = @ErrLine
            , @InErrorProcedure = @ErrProc
            , @outResultCode    = @outCode OUTPUT
            ;

    END CATCH;
END;
GO
