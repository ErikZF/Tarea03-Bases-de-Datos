CREATE OR ALTER PROCEDURE dbo.spAperturaSemana
    @inFechaJueves DATE
    , @outResultCode INT OUTPUT

AS
BEGIN
    SET NOCOUNT ON;

BEGIN TRY 

    SET @outResultCode = 0;

    -- semana siguiente, viernes (jueves + 1) al jueves (jueves + 7)
    DECLARE
        @FechaInicioSemana DATE = DATEADD(DAY,1, @inFechaJueves)
        , @FechaFinSemana DATE = DATEADD(DAY, 7 ,@inFechaJueves)
        , @idMes INT = NULL
        , @idSemana INT   = NULL
        , @UltimoDiaMes DATE = NULL
        , @FechaFinMes DATE = NULL
        , @NumJueves TINYINT = NULL
        , @DowUltimoDia INT = NULL
        ;
    
    -- Buscar si ya existe un Mes que cubra la semana que inicia
    SELECT @idMes = M.id
    FROM dbo.Mes AS M  
    WHERE (@FechaFinSemana BETWEEN M.FechaInicio AND M.FechaFin);


    --crear mes nuevo si no exite
    -- FechaInicio = prox Jueves
    -- FechaFin = ultimo ueves al mes calendario de ese viernens 
    -- NumJueves = canitdad de semanas en el periodo
    IF (@idMes IS NULL)
    BEGIN

        SET @UltimoDiaMes = EOMONTH(@FechaInicioSemana);

        -- Dom=1 Lun=2 Mar=3 Mie=4 Jue=5 Vie=6 Sab=7
        -- Resta los dias necesarios para llegar al jueves mas cercano hacia atras
        SET @DowUltimoDia  = DATEPART(dw, @UltimoDiaMes);
        SET @FechaFinMes   = DATEADD(DAY, -((@DowUltimoDia - 5 + 7) % 7), @UltimoDiaMes);

        -- Cada semana tiene exactamente un jueves => NumJueves = num semanas del periodo
        SET @NumJueves = (DATEDIFF(DAY, @FechaInicioSemana, @FechaFinMes) + 1) / 7;

        BEGIN TRANSACTION

            INSERT INTO dbo.Mes (
                FechaInicio
                , FechaFin
                , NumJueves
            )
            VALUES (
                @FechaInicioSemana
                , @FechaFinMes
                , @NumJueves
            );

            SET @idMes = SCOPE_IDENTITY();

        COMMIT TRANSACTION

    END;


    -- Crear registro de Semana

    BEGIN TRANSACTION

        INSERT INTO dbo.Semana (
            idMes
            , FechaInicio
            , FechaFin
        )
        VALUES (
            @idMes
            , @FechaInicioSemana
            , @FechaFinSemana
        );

        SET @idSemana = SCOPE_IDENTITY();

    COMMIT TRANSACTION

    -- Crear PlanillaSemanal para cada empleado activo

    BEGIN TRANSACTION

        INSERT INTO dbo.PlanillaSemanal (
            idEmpleado
            , idSemana
        )
        SELECT
            E.id
            , @idSemana
        FROM dbo.Empleado AS E
        WHERE (E.Activo = 1);

    COMMIT TRANSACTION

    -- Si el Mes es nuevo: crear PlanillaMensual y DeduccionXMes
    --  por cada empleado activo

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.PlanillaMensual AS PM
        WHERE (PM.idMes = @idMes)
    )
    BEGIN

        BEGIN TRANSACTION

            -- Encabezado mensual por empleado
            INSERT INTO dbo.PlanillaMensual (
                idEmpleado
                , idMes
            )
            SELECT
                E.id
                , @idMes
            FROM dbo.Empleado AS E
            WHERE (E.Activo = 1);

            -- Detalle de deducciones del mes por empleado
            INSERT INTO dbo.DeduccionXMes (
                idPlanillaMensual
                , idTipoDeduccion
            )
            SELECT
                PM.id
                , DE.idTipoDeduccion
            FROM dbo.PlanillaMensual AS PM
            INNER JOIN dbo.DeduccionEmpleado AS DE ON (DE.idEmpleado = PM.idEmpleado)
            WHERE (PM.idMes = @idMes)
                AND (DE.FechaInicio <= @FechaInicioSemana)
                AND (DE.FechaFin    >= @FechaInicioSemana);

        COMMIT TRANSACTION

    END;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE
        @ErrMsg   NVARCHAR(4000)  = ERROR_MESSAGE()
        , @ErrNum   INT           = ERROR_NUMBER()
        , @ErrSev   INT           = ERROR_SEVERITY()
        , @ErrStat  INT           = ERROR_STATE()
        , @ErrLine  INT           = ERROR_LINE()
        , @ErrProc  NVARCHAR(128) = ISNULL(ERROR_PROCEDURE(), '')
        , @outCode  INT           = 0
        ;

    SET @outResultCode = 50001;

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