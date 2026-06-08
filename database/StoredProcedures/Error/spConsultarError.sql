
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE OR ALTER PROCEDURE dbo.spConsultarError
    @inCodigoError VARCHAR(32)
    ,@outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    SET @outResultCode = 0

    BEGIN TRY
        SELECT 
            Err.Codigo
            ,Err.Descripcion
        FROM dbo.Error AS Err
        WHERE Err.Codigo = @inCodigoError
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
GO