
CREATE PROCEDURE dbo.spLogout
    @inIdUsuario INT
    ,@inIP    VARCHAR(50)
    ,@outResultCode INT OUTPUT

AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        SET @outResultCode = 0

        BEGIN TRANSACTION
            INSERT INTO dbo.BitacoraEvento (
                IdTipoEvento
                ,Descripcion
                ,IdPostByUser
                ,PostTime
                ,PostInIP
            )
            VALUES(
                4
                , NULL
                ,@inIdUsuario
                ,GETUTCDATE()
                ,@inIP
            )
            
        COMMIT TRANSACTION
        
    END TRY
    BEGIN CATCH

        IF (@@TRANCOUNT > 0 )
        BEGIN
            ROLLBACK TRANSACTION
        END

        SET @outResultCode = 50008

           DECLARE @ErrorNum INT = ERROR_NUMBER()
           DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE()
           DECLARE @ErrorSev INT = ERROR_SEVERITY()
           DECLARE @ErrorStat INT = ERROR_STATE()
           DECLARE @ErrorLine INT = ERROR_LINE()
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


