
CREATE PROCEDURE dbo.spActualizarEmpleado
     @inIdEmpleado          INT
    , @inValorDocIdentidad  VARCHAR(32)
    , @inNombre             VARCHAR(256)
    , @inIdDepartamento     INT
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

    DECLARE @JSONAntes          VARCHAR(1000)
    DECLARE @JSONDespues        VARCHAR(1000)

    -- Obtener datos actuales del empleado para la bitacora
    

    -- ##################### VALIDACIONES #####################
    

    -- Validar que de hecho exista un empleado con ese id
    IF NOT EXISTS (
        SELECT
            1
        FROM
            dbo.Empleado AS E
        WHERE 
            E.id = @inIdEmpleado
    )
        SET @outResultCode = 50012 -- No existe un empleado con ese id

    -- Validar que el nombre sea solo letras y espacios
    ELSE IF (@inNombre LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚüÜñÑ ]%')
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
        WHERE  E.ValorDocumento = @inValorDocIdentidad
        AND E.id <> @inIdEmpleado
    )
        SET @outResultCode = 50004

    -- Validar que no exista otro empleado con mismo nombre
    ELSE IF EXISTS (
        SELECT 
            1
        FROM   
            dbo.Empleado AS E
        WHERE  
            E.Nombre = @inNombre
            AND E.id <> @inIdEmpleado
    )
        SET @outResultCode = 50005


    -- ##################### FIN VALIDACIONES #####################

    SELECT 
        @JSONAntes = CONCAT(
                '{"ValorDocumento":"', E.ValorDocumento, 
                '","Nombre":"', E.Nombre, 
                '","IdPuesto":', E.idPuesto, 
                ',"IdDepartamento":', E.IdDepartamento, 
                ',"CuentaBancaria":"', E.CuentaBancaria, '"}'
            )
    FROM 
        dbo.Empleado AS E
    WHERE
        E.id = @inIdEmpleado


    SET @JSONDespues = CONCAT(
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
            7   -- TipoEvento: update no exitoso
            ,@inIdUsuario
            ,GETUTCDATE()
            ,CONCAT(
                'Fallo al editar empleado, Codigo de Error:'
                ,@outResultCode
                ,' Datos: '
                ,@JSONDespues)
            ,@inIP
        )

        RETURN
    END


    -- Actualizacion exitosa
    BEGIN TRANSACTION
    UPDATE E WITH(ROWLOCK)
    SET
        E.ValorDocumento = @inValorDocIdentidad
        , E.Nombre = @inNombre
        , E.IdPuesto = @inIdPuesto
        , E.CuentaBancaria = @inCuentaBancaria
        , E.IdDepartamento = @inIdDepartamento        
    FROM
        dbo.Empleado AS E
    WHERE  
        E.id = @inIdEmpleado

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
        8  -- TipoEvento: update exitoso
        ,@inIdUsuario
        ,GETUTCDATE()
        ,CONCAT(
            'Exito al editar empleado'
            ,' DatosAntes: '
            ,@JSONAntes
            ,' DatosDespues: '
            ,@JSONDespues)
        ,@inIP
    )
    COMMIT TRANSACTION

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