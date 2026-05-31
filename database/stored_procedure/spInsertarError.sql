
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

CREATE OR ALTER PROCEDURE dbo.spInsertarError
    @InErrorNumber INT,
    @InErrorMessage NVARCHAR(4000),
    @InErrorSeverity INT,
    @InErrorState INT,
    @InErrorLine INT,
    @InErrorProcedure NVARCHAR(128),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    SET @outResultCode = 0
    
    BEGIN TRY
        INSERT INTO dbo.DBError (
            UserName, 
            [Number], 
            [State], 
            [Severity], 
            [Line], 
            [Procedure], 
            [Message], 
            [DateTime]
        )
        VALUES 
        (
            SUSER_SNAME(),
            @InErrorNumber,
            @InErrorState,
            @InErrorSeverity,
            @InErrorLine,
            @InErrorProcedure,
            @InErrorMessage,
            GETUTCDATE()
        );
        
        SET @outResultCode = 50008;
    END TRY
    BEGIN CATCH 
        -- Si falla la inserción del error, retornar código de error
        SET @outResultCode = 50008;
    END CATCH
END
GO