CREATE OR ALTER PROCEDURE dbo.spInsertarBitacoraEvento
    @inIdTipoEvento INT
    , @inIdUsuario  INT
    , @inIP         VARCHAR(50)
    , @inDescripcion VARCHAR(500)
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;

    INSERT INTO dbo.BitacoraEvento (
        IdTipoEvento
        , IdPostByUser
        , PostInIP
        , Descripcion
    )
    VALUES (
        @inIdTipoEvento
        , @inIdUsuario
        , @inIP
        , ISNULL(@inDescripcion, '')
    );

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE
        @ErrMsg  NVARCHAR(4000)  = ERROR_MESSAGE()
        , @ErrNum  INT           = ERROR_NUMBER()
        , @ErrSev  INT           = ERROR_SEVERITY()
        , @ErrStat INT           = ERROR_STATE()
        , @ErrLine INT           = ERROR_LINE()
        , @ErrProc NVARCHAR(128) = ISNULL(ERROR_PROCEDURE(), '')
        , @outCode INT           = 0
        ;

    SET @outResultCode = 50008;

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

SET NOCOUNT OFF;
END;
GO
