CREATE OR ALTER PROCEDURE dbo.spProcesarMarcaAsistencia
    @inValorDocumento VARCHAR(20) 
    , @inHoraEntrada DATETIME
    , @inHoraSalida DATETIME
    , @inFechaOperacion DATE
    , @outResultCode INT OUTPUT

AS
BEGIN

    SET NOCOUNT ON;

BEGIN TRY

    SET @outResultCode = 0
    
    -- Buscar empleado y su salario
    DECLARE @idEmpleado INT, @SalarioXHora DECIMAL(10,2);

    SELECT
        @idEmpleado = E.id
        , @SalarioXHora = P.SalarioXHora
    FROM dbo.Empleado AS E
    INNER JOIN dbo.Puesto AS P ON (P.id = E.idPuesto)
    WHERE (E.ValorDocumento = @inValorDocumento)
        AND (E.Activo = 1);
    
    -- control
    IF (@idEmpleado IS NULL)
    BEGIN
        SET @outResultCode = 50002;
        RETURN;
    END;

    --Buscar semana y horario jornada

    DECLARE @idSemana INT;

    SELECT @idSemana = S.id
    FROM dbo.Semana AS S
    WHERE (@inFechaOperacion BETWEEN S.FechaInicio AND S.FechaFin);

    IF (@idSemana IS NULL)
    BEGIN
        SET @outResultCode = 50003;
        RETURN;
    END;

    DECLARE @idHorarioJornada INT, @HoraFinJornada TIME;

    SELECT
        @idHorarioJornada = HJ.id
        , @HoraFinJornada = TJ.HoraFin
    FROM dbo.HorarioJornada AS HJ
    INNER JOIN dbo.TipoJornada AS TJ ON (TJ.id = HJ.idTipoJornada)
    WHERE (HJ.idEmpleado = @idEmpleado)
        AND (HJ.idSemana = @idSemana);

    IF (@idHorarioJornada IS NULL)
    BEGIN
        SET @outResultCode = 50004;
        RETURN;
    END;

    -- calcular fin de jornada
    DECLARE @JornadaFin DATETIME

    SET @JornadaFin = CAST (
        CAST(@inFechaOperacion AS VARCHAR(10)) + ' ' + CAST(@HoraFinJornada AS VARCHAR(8))
        AS DATETIME
    );

    -- si horafin < 12:00 es nocturna => fin es el dia siguiente
    IF (@HoraFinJornada < '12:00:00')
        SET @JornadaFin = DATEADD(DAY, 1, @JornadaFin);
    
    -- calcular horas
    DECLARE 
        @MinTrabajados INT = DATEDIFF(MINUTE, @inHoraEntrada, @inHoraSalida)
        , @MinJornada INT = DATEDIFF(MINUTE, @inHoraEntrada, @JornadaFin)
        , @HorasOrdinarias  DECIMAL(6,2) = 0
        , @HorasExtraNormal DECIMAL(6,2) = 0
        , @HorasExtraDoble  DECIMAL(6,2) = 0
        ;

    -- Si salio antes del fin de jornada, limitar minutos de jornada
    IF (@MinJornada > @MinTrabajados)
        SET @MinJornada = @MinTrabajados;

    -- Solo horas completas
    SET @HorasOrdinarias = FLOOR(@MinJornada / 60.0);

    -- Horas extra: si la salida supera el fin de jornada
    IF (@inHoraSalida > @JornadaFin)
    BEGIN
        DECLARE
            @MinExtraTotal INT = DATEDIFF(MINUTE, @JornadaFin, @inHoraSalida)
            , @EsDomFeriado BIT = 0
            ;

        -- Domingo: con DATEFIRST=7, dw=1
        IF (DATEPART(dw, @inFechaOperacion) = 1)
            SET @EsDomFeriado = 1;

        IF EXISTS (SELECT 1 FROM dbo.Feriado AS F WHERE (F.Fecha = @inFechaOperacion))
            SET @EsDomFeriado = 1;

        IF (@EsDomFeriado = 1)
            SET @HorasExtraDoble = FLOOR(@MinExtraTotal / 60.0);
        ELSE
            SET @HorasExtraNormal = FLOOR(@MinExtraTotal / 60.0);
    END;

    -- Calcular montos
    DECLARE
        @MontoOrdinario DECIMAL(12,2) = @HorasOrdinarias  * @SalarioXHora
        , @MontoExtraNormal DECIMAL(12,2) = @HorasExtraNormal * @SalarioXHora * 1.5
        , @MontoExtraDoble  DECIMAL(12,2) = @HorasExtraDoble  * @SalarioXHora * 2.0
        ;

    -- Buscar PlanillaSemanal y saldo acumulado actual
    DECLARE
        @idPlanillaSemanal INT
        , @SaldoActual DECIMAL(12,2)
        ;

    SELECT
        @idPlanillaSemanal = PS.id
        , @SaldoActual = PS.SalarioBruto
    FROM dbo.PlanillaSemanal AS PS
    WHERE (PS.idEmpleado = @idEmpleado)
        AND (PS.idSemana = @idSemana);

    IF (@idPlanillaSemanal IS NULL)
    BEGIN
        SET @outResultCode = 50005;
        RETURN;
    END;

    BEGIN TRANSACTION

        -- Insertar MarcaAsistencia
        DECLARE @idMarca INT;

        INSERT INTO dbo.MarcaAsistencia (
            idEmpleado
            , idHorarioJornada
            , Fecha
            , HoraEntrada
            , HoraSalida
        )
        VALUES (
            @idEmpleado
            , @idHorarioJornada
            , @inFechaOperacion
            , @inHoraEntrada
            , @inHoraSalida
        );

        SET @idMarca = SCOPE_IDENTITY();

        -- Crear Comprobante tipo H
        DECLARE @idComprobante INT;

        INSERT INTO dbo.Comprobante (idPlanillaSemanal, Tipo)
        VALUES (@idPlanillaSemanal, 'H');

        SET @idComprobante = SCOPE_IDENTITY();

        -- ComprobanteHora: puente entre Comprobante y MarcaAsistencia
        INSERT INTO dbo.ComprobanteHora (idComprobante, idMarcaAsistencia)
        VALUES (@idComprobante, @idMarca);

        -- MovPlanilla: un movimiento por tipo de hora (solo si hay horas)
        IF (@HorasOrdinarias > 0)
        BEGIN
            SET @SaldoActual = @SaldoActual + @MontoOrdinario;
            INSERT INTO dbo.MovPlanilla (idComprobante, idTipoMovimiento, Monto, NuevoSaldo)
            VALUES (@idComprobante, 1, @MontoOrdinario, @SaldoActual);
        END;

        IF (@HorasExtraNormal > 0)
        BEGIN
            SET @SaldoActual = @SaldoActual + @MontoExtraNormal;
            INSERT INTO dbo.MovPlanilla (idComprobante, idTipoMovimiento, Monto, NuevoSaldo)
            VALUES (@idComprobante, 2, @MontoExtraNormal, @SaldoActual);
        END;

        IF (@HorasExtraDoble > 0)
        BEGIN
            SET @SaldoActual = @SaldoActual + @MontoExtraDoble;
            INSERT INTO dbo.MovPlanilla (idComprobante, idTipoMovimiento, Monto, NuevoSaldo)
            VALUES (@idComprobante, 3, @MontoExtraDoble, @SaldoActual);
        END;

        -- Actualizar acumuladores de PlanillaSemanal
        UPDATE dbo.PlanillaSemanal WITH (ROWLOCK)
        SET
            HorasOrdinarias = HorasOrdinarias + @HorasOrdinarias
            , HorasExtraNormal = HorasExtraNormal + @HorasExtraNormal
            , HorasExtraDoble = HorasExtraDoble + @HorasExtraDoble
            , SalarioBruto = SalarioBruto + @MontoOrdinario + @MontoExtraNormal + @MontoExtraDoble
        WHERE (id = @idPlanillaSemanal);

    COMMIT TRANSACTION

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE
        @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE()
        , @ErrNum INT = ERROR_NUMBER()
        , @ErrSev INT = ERROR_SEVERITY()
        , @ErrStat INT = ERROR_STATE()
        , @ErrLine INT = ERROR_LINE()
        , @ErrProc NVARCHAR(128) = ISNULL(ERROR_PROCEDURE(), '')
        , @outCode INT  = 0
        ;

    SET @outResultCode = 50001;

    EXEC dbo.spInsertarError
        @InErrorNumber = @ErrNum
        , @InErrorMessage = @ErrMsg
        , @InErrorSeverity = @ErrSev
        , @InErrorState  = @ErrStat
        , @InErrorLine = @ErrLine
        , @InErrorProcedure = @ErrProc
        , @outResultCode = @outCode OUTPUT
        ;

END CATCH;

SET NOCOUNT OFF;
END;
GO
