CREATE PROCEDURE dbo.spInsertarEmpleado
     @inValorDocIdentidad   VARCHAR(64)
    , @inNombre             VARCHAR(256)
    , @inIdPuesto           INT
    , @inIdUsuario          INT
    , @inCuentaBancaria     VARCHAR(30)
    , @inIP                 VARCHAR(50)
    , @outResultCode        INT OUTPUT
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY

    SET @outResultCode = 0

    DECLARE @ParametrosJSON VARCHAR(500) = NULL
    DECLARE @_bitacoraRC    INT          = 0
    DECLARE @_desc          VARCHAR(500) = NULL

    -- ##################### VALIDACIONES #####################

    IF (@inNombre LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚüÜñÑ ]%')
        SET @outResultCode = 50009

    ELSE IF (@inValorDocIdentidad LIKE '%[^0-9]%')
        SET @outResultCode = 50010

    ELSE IF EXISTS (
        SELECT 1 FROM dbo.Empleado AS E
        WHERE E.ValorDocumento = @inValorDocIdentidad
    )
        SET @outResultCode = 50004

    ELSE IF EXISTS (
        SELECT 1 FROM dbo.Empleado AS E
        WHERE E.Nombre = @inNombre
    )
        SET @outResultCode = 50005

    -- ##################### FIN VALIDACIONES #####################

    SET @ParametrosJSON = CONCAT(
        '{"ValorDocumento":"', @inValorDocIdentidad,
        '","Nombre":"', @inNombre,
        '","IdPuesto":', @inIdPuesto,
        ',"CuentaBancaria":"', @inCuentaBancaria, '"}'
    );

    IF (@outResultCode <> 0)
    BEGIN
        SET @_desc = CONCAT('Fallo al insertar empleado. Cod:', @outResultCode, ' ', @ParametrosJSON);
        EXEC dbo.spInsertarBitacoraEvento
            @inIdTipoEvento  = 5
            , @inIdUsuario   = @inIdUsuario
            , @inIP          = @inIP
            , @inDescripcion = @_desc
            , @outResultCode = @_bitacoraRC OUTPUT;
        RETURN
    END

    BEGIN TRANSACTION

    INSERT INTO dbo.Empleado (
        idPuesto
        ,idUsuario
        ,ValorDocumento
        ,Nombre
        ,CuentaBancaria
        ,FechaContratacion
        ,Activo
    )
    VALUES (
        @inIdPuesto
        , @inIdUsuario
        , @inValorDocIdentidad
        , @inNombre
        , @inCuentaBancaria
        , GETUTCDATE()
        , 1
    )

    SET @_desc = CONCAT('Empleado insertado exitosamente: ', @ParametrosJSON);
    EXEC dbo.spInsertarBitacoraEvento
        @inIdTipoEvento  = 6
        , @inIdUsuario   = @inIdUsuario
        , @inIP          = @inIP
        , @inDescripcion = @_desc
        , @outResultCode = @_bitacoraRC OUTPUT;

    COMMIT TRANSACTION

END TRY
BEGIN CATCH

    IF (@@TRANCOUNT > 0)
        ROLLBACK TRANSACTION

    SET @outResultCode = 50008

    DECLARE @ErrorNum  INT            = ERROR_NUMBER()
    DECLARE @ErrorMsg  NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSev  INT            = ERROR_SEVERITY()
    DECLARE @ErrorStat INT            = ERROR_STATE()
    DECLARE @ErrorLine INT            = ERROR_LINE()
    DECLARE @ErrorProc NVARCHAR(128)  = ERROR_PROCEDURE()

    EXEC dbo.spInsertarError
         @InErrorNumber    = @ErrorNum
        ,@InErrorMessage   = @ErrorMsg
        ,@InErrorSeverity  = @ErrorSev
        ,@InErrorState     = @ErrorStat
        ,@InErrorLine      = @ErrorLine
        ,@InErrorProcedure = @ErrorProc
        ,@outResultCode    = @outResultCode OUTPUT

END CATCH
END
