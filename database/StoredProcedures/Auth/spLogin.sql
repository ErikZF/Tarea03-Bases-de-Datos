CREATE OR ALTER PROCEDURE dbo.spLogin  
    @inUsername VARCHAR(60)
    , @inPassword VARCHAR(256)
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0;
    
    IF NOT EXISTS(
        SELECT 1 
        FROM dbo.Usuario AS U
        WHERE (U.Username = @inUsername)
            
    )
    BEGIN
        SET @outResultCode = 50001;
        RETURN;
    END;

    IF NOT EXISTS(
        SELECT 1 
        FROM dbo.Usuario AS U
        WHERE (U.Username = @inUsername)
            AND (U.PasswordHash = @inPassword)
    )
    BEGIN
        SET @outResultCode = 50002;
        RETURN;
    END;

    SELECT 
        U.id AS UserId
        , U.Username AS Username
        , U.Tipo AS Tipo
        , E.id AS IdEmpleado
    FROM dbo.Usuario AS U
    LEFT JOIN dbo.Empleado AS E ON (E.idUsuario = U.id)
    WHERE (U.Username = @inUsername)
        AND (U.PasswordHash = @inPassword);
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

    DECLARE
        @ErrMsg NVARCHAR(4000)  = ERROR_MESSAGE()
        , @ErrNum INT  = ERROR_NUMBER()
        , @ErrSev INT  = ERROR_SEVERITY()
        , @ErrStat INT = ERROR_STATE()
        , @ErrLine INT= ERROR_LINE()
        , @ErrProc NVARCHAR(128) = ISNULL(ERROR_PROCEDURE(), '')
        , @outCode INT= 0
        ;

    SET @outResultCode = 50001;

    EXEC dbo.spInsertarError
        @InErrorNumber = @ErrNum
        , @InErrorMessage = @ErrMsg
        , @InErrorSeverity = @ErrSev
        , @InErrorState = @ErrStat
        , @InErrorLine = @ErrLine
        , @InErrorProcedure = @ErrProc
        , @outResultCode = @outCode OUTPUT
        ;

END CATCH;

SET NOCOUNT OFF;
END;
GO