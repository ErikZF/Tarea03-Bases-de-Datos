CREATE PROCEDURE dbo.spInsertarEmpleado
     @inValorDocIdentidad   VARCHAR(64)
    , @inNombre             VARCHAR(256)
    , @inIdDepartamento     INT
    , @inIdTipoDocumento    INT
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

    DECLARE @NombrePuesto       VARCHAR(100) = NULL
    DECLARE @ParametrosJSON     VARCHAR(1000) = NULL


    -- ##################### VALIDACIONES #####################
    
    -- Validar que el nombre sea solo letras y espacios
    IF (@inNombre LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚüÜñÑ ]%')
        SET @outResultCode = 50009

    -- Validar que el documento de identidad sea numerico
    ELSE IF (@inValorDocIdentidad LIKE '%[^0-9]%')
        SET @outResultCode = 50010


    -- Validar que no exista otro empleado con mismo documento
    ELSE IF EXISTS (
        SELECT 
            1
        FROM   
            dbo.Empleado AS E
        WHERE  (E.ValorDocumento = @inValorDocIdentidad)
    )
        SET @outResultCode = 50004

    -- Validar que no exista otro empleado con mismo nombre
    ELSE IF EXISTS (
        SELECT 
            1
        FROM   
            dbo.Empleado AS E
        WHERE  
            (E.Nombre = @inNombre)
    )
        SET @outResultCode = 50005


    -- ##################### FIN VALIDACIONES #####################

    -- Llenar la descripcion del evento con los datos del empleado
    SET @ParametrosJSON = CONCAT(
                '{"ValorDocumento":"', @inValorDocIdentidad, 
                '","Nombre":"', @inNombre, 
                '","IdPuesto":', @inIdPuesto, 
                ',"IdDepartamento":', @inIdDepartamento, 
                ',"CuentaBancaria":"', @inCuentaBancaria, '"}'
            );


    -- en caso de que haya fallado el SP en alguna validacion
    IF (@outResultCode <> 0)
    BEGIN

    
        INSERT INTO dbo.BitacoraEvento 
    (
        IdTipoEvento
        ,idUsuario
        ,FechaHora
        ,Descripcion
        ,IP
        )
    VALUES 
    (
        5    -- TipoEvento: insercion no exitosa
        ,@inIdUsuario
        ,GETUTCDATE()
        ,CONCAT(
            'Fallo al insertar empleado, Codigo de Error:'
            ,@outResultCode
            ,' Datos: '
            ,@ParametrosJSON)
        ,@inIP
    )

        RETURN
    END
    

    BEGIN TRANSACTION


    -- Insercion exitosa
    INSERT INTO dbo.Empleado (
        idPuesto
        ,idDepartamento
        ,idTipoDocumento
        ,idUsuario
        ,ValorDocumento
        ,Nombre
        ,CuentaBancaria
        ,FechaContratacion
        ,Activo 
    )
    VALUES (
        @inIdPuesto
        , @inIdDepartamento
        , @inIdTipoDocumento
        , @inIdUsuario
        , @inValorDocIdentidad
        , @inNombre
        , @inCuentaBancaria
        , GETUTCDATE() 
        , 1 -- Activo por defecto
    )

    INSERT INTO dbo.BitacoraEvento (
        IdTipoEvento
        ,idUsuario
        ,FechaHora
        ,Descripcion
        ,IP
    )
    VALUES 
    (
        6 -- TipoEvento: insercion exitosa
        ,@inIdUsuario
        ,GETUTCDATE()
        ,CONCAT('Empleado insertado exitosamente: ', @ParametrosJSON)
        ,@inIP
    )


    COMMIT TRANSACTION

END TRY
BEGIN CATCH

        IF (@@TRANCOUNT > 0)
        BEGIN
            ROLLBACK TRANSACTION
        END

        SET @outResultCode = 50008

        DECLARE @ErrorNum INT = ERROR_NUMBER()
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE()
        DECLARE @ErrorSev INT = ERROR_SEVERITY()
        DECLARE @ErrorStat INT = ERROR_STATE()
        DECLARE @ErrorLine INT = ERROR_LINE()
        DECLARE @ErrorProc NVARCHAR(128) = ERROR_PROCEDURE()

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