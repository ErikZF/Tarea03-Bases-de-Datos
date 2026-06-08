CREATE PROCEDURE dbo.spActualizarEmpleado
     @inIdEmpleado          INT
    , @inValorDocIdentidad  VARCHAR(32)
    , @inNombre             VARCHAR(256)
    , @inCuentaBancaria     VARCHAR(32)
    , @inIdPuesto           INT
    , @inIdUsuario          INT
    , @inIP                 VARCHAR(50)
    , @outResultCode        INT OUTPUT
AS
BEGIN
BEGIN TRY
SET NOCOUNT ON

    SET @outResultCode = 0

    DECLARE @JSONAntes   VARCHAR(500) = NULL
    DECLARE @JSONDespues VARCHAR(500) = NULL
    DECLARE @_bitacoraRC INT          = 0
    DECLARE @_desc       VARCHAR(500) = NULL

    -- ##################### VALIDACIONES #####################

    IF NOT EXISTS (
        SELECT 1 FROM dbo.Empleado AS E WHERE E.id = @inIdEmpleado
    )
        SET @outResultCode = 50012

    ELSE IF (@inNombre LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚüÜñÑ ]%')
        SET @outResultCode = 50009

    ELSE IF (@inValorDocIdentidad LIKE '%[^0-9]%')
        SET @outResultCode = 50010

    ELSE IF EXISTS (
        SELECT 1 FROM dbo.Empleado AS E
        WHERE E.ValorDocumento = @inValorDocIdentidad AND E.id <> @inIdEmpleado
    )
        SET @outResultCode = 50006

    ELSE IF EXISTS (
        SELECT 1 FROM dbo.Empleado AS E
        WHERE E.Nombre = @inNombre AND E.id <> @inIdEmpleado
    )
        SET @outResultCode = 50007

    -- ##################### FIN VALIDACIONES #####################

    SELECT
        @JSONAntes = CONCAT(
            '{"ValorDocumento":"', E.ValorDocumento,
            '","Nombre":"', E.Nombre,
            '","IdPuesto":', E.idPuesto,
            ',"CuentaBancaria":"', E.CuentaBancaria, '"}'
        )
    FROM dbo.Empleado AS E
    WHERE E.id = @inIdEmpleado

    SET @JSONDespues = CONCAT(
        '{"ValorDocumento":"', @inValorDocIdentidad,
        '","Nombre":"', @inNombre,
        '","IdPuesto":', @inIdPuesto,
        ',"CuentaBancaria":"', @inCuentaBancaria, '"}'
    );

    IF (@outResultCode <> 0)
    BEGIN
        SET @_desc = CONCAT('Fallo al editar empleado. Cod:', @outResultCode, ' ', @JSONDespues);
        EXEC dbo.spInsertarBitacoraEvento
            @inIdTipoEvento  = 7
            , @inIdUsuario   = @inIdUsuario
            , @inIP          = @inIP
            , @inDescripcion = @_desc
            , @outResultCode = @_bitacoraRC OUTPUT;
        RETURN
    END

    BEGIN TRANSACTION
    UPDATE E WITH(ROWLOCK)
    SET
        E.ValorDocumento = @inValorDocIdentidad
        , E.Nombre       = @inNombre
        , E.IdPuesto     = @inIdPuesto
        , E.CuentaBancaria = @inCuentaBancaria
    FROM dbo.Empleado AS E
    WHERE E.id = @inIdEmpleado

    SET @_desc = CONCAT('Empleado editado. Antes:', @JSONAntes, ' Despues:', @JSONDespues);
    EXEC dbo.spInsertarBitacoraEvento
        @inIdTipoEvento  = 8
        , @inIdUsuario   = @inIdUsuario
        , @inIP          = @inIP
        , @inDescripcion = @_desc
        , @outResultCode = @_bitacoraRC OUTPUT;

    COMMIT TRANSACTION

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SET @outResultCode = 50008;

    DECLARE @ErrorNum  INT            = ERROR_NUMBER();
    DECLARE @ErrorMsg  NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSev  INT            = ERROR_SEVERITY();
    DECLARE @ErrorStat INT            = ERROR_STATE();
    DECLARE @ErrorLine INT            = ERROR_LINE();
    DECLARE @ErrorProc NVARCHAR(128)  = ERROR_PROCEDURE();

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
