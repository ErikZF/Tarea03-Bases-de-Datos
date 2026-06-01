
-- 01_create_tables.sql
-- Creacion de tablas - Control de Asistencia y Planilla Obrera

USE DBPlanilla;
GO

-- CATALOGOS (sin dependencias)

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Puesto' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Puesto (
        id  INT  IDENTITY(1,1) NOT NULL
        , Nombre  VARCHAR(100)  NOT NULL
        , SalarioXHora DECIMAL(10,2) NOT NULL
        , CONSTRAINT PK_Puesto PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoDocIdentidad' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.TipoDocIdentidad (
        id  INT   NOT NULL
        , Nombre VARCHAR(60) NOT NULL
        , CONSTRAINT PK_TipoDocIdentidad PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Departamento' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Departamento (
        id  INT NOT NULL
        , Nombre VARCHAR(100)  NOT NULL
        , CONSTRAINT PK_Departamento PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoJornada' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.TipoJornada (
        id  INT NOT NULL
        , Nombre VARCHAR(60) NOT NULL
        , HoraInicio TIME  NOT NULL
        , HoraFin TIME  NOT NULL
        , CONSTRAINT PK_TipoJornada PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Feriado' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Feriado (
        id       INT          NOT NULL
        , Nombre VARCHAR(100) NOT NULL
        , Fecha  DATE         NOT NULL
        , CONSTRAINT PK_Feriado PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoMovimiento' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.TipoMovimiento (
        id       INT          NOT NULL
        , Nombre VARCHAR(100) NOT NULL
        , Accion CHAR(1)      NOT NULL  -- C=credito, D=debito
        , CONSTRAINT PK_TipoMovimiento PRIMARY KEY (id)
        , CONSTRAINT CHK_TipoMovimiento_Accion CHECK (Accion IN ('C', 'D'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoDeduccion' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.TipoDeduccion (
        id               INT           NOT NULL
        , Nombre         VARCHAR(100)  NOT NULL
        , EsObligatoria  BIT           NOT NULL
        , EsPorcentual   BIT           NOT NULL
        , Valor          DECIMAL(5,4)  NOT NULL CONSTRAINT DF_TipoDeduccion_Valor DEFAULT 0
        , CONSTRAINT PK_TipoDeduccion PRIMARY KEY (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TipoEvento' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.TipoEvento (
        id       INT          NOT NULL
        , Nombre VARCHAR(100) NOT NULL
        , CONSTRAINT PK_TipoEvento PRIMARY KEY (id)
    );
END
GO

-- USUARIOS


IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Usuario' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Usuario (
        id             INT           IDENTITY(1,1) NOT NULL
        , Username     VARCHAR(60)   NOT NULL
        , PasswordHash VARCHAR(256)  NOT NULL
        , Tipo         TINYINT       NOT NULL  -- 1=admin, 2=empleado
        , CONSTRAINT PK_Usuario PRIMARY KEY (id)
        , CONSTRAINT UQ_Usuario_Username UNIQUE (Username)
        , CONSTRAINT CHK_Usuario_Tipo CHECK (Tipo IN (1, 2))
    );
END
GO

-- EMPLEADOS


IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Empleado' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Empleado (
        id                  INT           IDENTITY(1,1) NOT NULL
        , idPuesto          INT           NOT NULL
        , idDepartamento    INT           NOT NULL
        , idTipoDocumento   INT           NOT NULL
        , idUsuario         INT           NOT NULL
        , ValorDocumento    VARCHAR(20)   NOT NULL
        , Nombre            VARCHAR(150)  NOT NULL
        , CuentaBancaria    VARCHAR(30)   NOT NULL
        , FechaContratacion DATE          NOT NULL
        , Activo            BIT           NOT NULL CONSTRAINT DF_Empleado_Activo DEFAULT 1
        , CONSTRAINT PK_Empleado PRIMARY KEY (id)
        , CONSTRAINT FK_Empleado_Puesto        FOREIGN KEY (idPuesto)        REFERENCES dbo.Puesto (id)
        , CONSTRAINT FK_Empleado_Departamento  FOREIGN KEY (idDepartamento)  REFERENCES dbo.Departamento (id)
        , CONSTRAINT FK_Empleado_TipoDoc       FOREIGN KEY (idTipoDocumento) REFERENCES dbo.TipoDocIdentidad (id)
        , CONSTRAINT FK_Empleado_Usuario       FOREIGN KEY (idUsuario)       REFERENCES dbo.Usuario (id)
    );
END
GO

-- TIEMPO


IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Mes' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Mes (
        id           INT     IDENTITY(1,1) NOT NULL
        , FechaInicio DATE   NOT NULL
        , FechaFin    DATE   NOT NULL
        , NumJueves   TINYINT NOT NULL  -- 4 o 5
        , CONSTRAINT PK_Mes PRIMARY KEY (id)
        , CONSTRAINT CHK_Mes_NumJueves CHECK (NumJueves IN (4, 5))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Semana' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Semana (
        id           INT  IDENTITY(1,1) NOT NULL
        , idMes      INT  NOT NULL
        , FechaInicio DATE NOT NULL
        , FechaFin    DATE NOT NULL
        , CONSTRAINT PK_Semana PRIMARY KEY (id)
        , CONSTRAINT FK_Semana_Mes FOREIGN KEY (idMes) REFERENCES dbo.Mes (id)
    );
END
GO

-- ASISTENCIA


IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HorarioJornada' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.HorarioJornada (
        id               INT  IDENTITY(1,1) NOT NULL
        , idEmpleado     INT  NOT NULL
        , idSemana       INT  NOT NULL
        , idTipoJornada  INT  NOT NULL
        , CONSTRAINT PK_HorarioJornada PRIMARY KEY (id)
        , CONSTRAINT FK_HorarioJornada_Empleado    FOREIGN KEY (idEmpleado)    REFERENCES dbo.Empleado (id)
        , CONSTRAINT FK_HorarioJornada_Semana      FOREIGN KEY (idSemana)      REFERENCES dbo.Semana (id)
        , CONSTRAINT FK_HorarioJornada_TipoJornada FOREIGN KEY (idTipoJornada) REFERENCES dbo.TipoJornada (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MarcaAsistencia' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.MarcaAsistencia (
        id                  INT       IDENTITY(1,1) NOT NULL
        , idEmpleado        INT       NOT NULL
        , idHorarioJornada  INT       NOT NULL
        , Fecha             DATE      NOT NULL
        , HoraEntrada       DATETIME  NOT NULL
        , HoraSalida        DATETIME  NOT NULL  -- ETL solo inserta cuando tiene ambas marcas
        , CONSTRAINT PK_MarcaAsistencia PRIMARY KEY (id)
        , CONSTRAINT FK_MarcaAsistencia_Empleado       FOREIGN KEY (idEmpleado)       REFERENCES dbo.Empleado (id)
        , CONSTRAINT FK_MarcaAsistencia_HorarioJornada FOREIGN KEY (idHorarioJornada) REFERENCES dbo.HorarioJornada (id)
    );
END
GO

-- PLANILLA SEMANAL

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PlanillaSemanal' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.PlanillaSemanal (
        id                  INT            IDENTITY(1,1) NOT NULL
        , idEmpleado        INT            NOT NULL
        , idSemana          INT            NOT NULL
        , SalarioBruto      DECIMAL(12,2)  NOT NULL CONSTRAINT DF_PlanillaSemanal_SalarioBruto     DEFAULT 0
        , TotalDeducciones  DECIMAL(12,2)  NOT NULL CONSTRAINT DF_PlanillaSemanal_TotalDeducciones DEFAULT 0
        , SalarioNeto       DECIMAL(12,2)  NOT NULL CONSTRAINT DF_PlanillaSemanal_SalarioNeto      DEFAULT 0
        , HorasOrdinarias   DECIMAL(6,2)   NOT NULL CONSTRAINT DF_PlanillaSemanal_HorasOrdinarias  DEFAULT 0
        , HorasExtraNormal  DECIMAL(6,2)   NOT NULL CONSTRAINT DF_PlanillaSemanal_HorasExtraNormal DEFAULT 0
        , HorasExtraDoble   DECIMAL(6,2)   NOT NULL CONSTRAINT DF_PlanillaSemanal_HorasExtraDoble  DEFAULT 0
        , CONSTRAINT PK_PlanillaSemanal PRIMARY KEY (id)
        , CONSTRAINT FK_PlanillaSemanal_Empleado FOREIGN KEY (idEmpleado) REFERENCES dbo.Empleado (id)
        , CONSTRAINT FK_PlanillaSemanal_Semana   FOREIGN KEY (idSemana)   REFERENCES dbo.Semana (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Comprobante' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Comprobante (
        id                   INT       IDENTITY(1,1) NOT NULL
        , idPlanillaSemanal  INT       NOT NULL
        , Tipo               CHAR(1)   NOT NULL  -- H=horas, D=deducciones
        , FechaHora          DATETIME  NOT NULL CONSTRAINT DF_Comprobante_FechaHora DEFAULT GETUTCDATE()
        , CONSTRAINT PK_Comprobante PRIMARY KEY (id)
        , CONSTRAINT FK_Comprobante_PlanillaSemanal FOREIGN KEY (idPlanillaSemanal) REFERENCES dbo.PlanillaSemanal (id)
        , CONSTRAINT CHK_Comprobante_Tipo CHECK (Tipo IN ('H', 'D'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ComprobanteHora' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ComprobanteHora (
        id                   INT  IDENTITY(1,1) NOT NULL
        , idComprobante      INT  NOT NULL
        , idMarcaAsistencia  INT  NOT NULL
        , CONSTRAINT PK_ComprobanteHora PRIMARY KEY (id)
        , CONSTRAINT FK_ComprobanteHora_Comprobante     FOREIGN KEY (idComprobante)     REFERENCES dbo.Comprobante (id)
        , CONSTRAINT FK_ComprobanteHora_MarcaAsistencia FOREIGN KEY (idMarcaAsistencia) REFERENCES dbo.MarcaAsistencia (id)
        , CONSTRAINT UQ_ComprobanteHora_Comprobante UNIQUE (idComprobante)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MovPlanilla' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.MovPlanilla (
        id                  INT            IDENTITY(1,1) NOT NULL
        , idComprobante     INT            NOT NULL
        , idTipoMovimiento  INT            NOT NULL
        , Monto             DECIMAL(12,2)  NOT NULL
        , SaldoBrutoAcum    DECIMAL(12,2)  NOT NULL  -- patron saldo-movimiento
        , CONSTRAINT PK_MovPlanilla PRIMARY KEY (id)
        , CONSTRAINT FK_MovPlanilla_Comprobante    FOREIGN KEY (idComprobante)    REFERENCES dbo.Comprobante (id)
        , CONSTRAINT FK_MovPlanilla_TipoMovimiento FOREIGN KEY (idTipoMovimiento) REFERENCES dbo.TipoMovimiento (id)
    );
END
GO

-- PLANILLA MENSUAL

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PlanillaMensual' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.PlanillaMensual (
        id                  INT            IDENTITY(1,1) NOT NULL
        , idEmpleado        INT            NOT NULL
        , idMes             INT            NOT NULL
        , SalarioBruto      DECIMAL(12,2)  NOT NULL CONSTRAINT DF_PlanillaMensual_SalarioBruto     DEFAULT 0
        , TotalDeducciones  DECIMAL(12,2)  NOT NULL CONSTRAINT DF_PlanillaMensual_TotalDeducciones DEFAULT 0
        , SalarioNeto       DECIMAL(12,2)  NOT NULL CONSTRAINT DF_PlanillaMensual_SalarioNeto      DEFAULT 0
        , CONSTRAINT PK_PlanillaMensual PRIMARY KEY (id)
        , CONSTRAINT FK_PlanillaMensual_Empleado FOREIGN KEY (idEmpleado) REFERENCES dbo.Empleado (id)
        , CONSTRAINT FK_PlanillaMensual_Mes      FOREIGN KEY (idMes)      REFERENCES dbo.Mes (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DeduccionXMes' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.DeduccionXMes (
        id                   INT            IDENTITY(1,1) NOT NULL
        , idPlanillaMensual  INT            NOT NULL
        , idTipoDeduccion    INT            NOT NULL
        , MontoTotal         DECIMAL(12,2)  NOT NULL CONSTRAINT DF_DeduccionXMes_MontoTotal DEFAULT 0
        , CONSTRAINT PK_DeduccionXMes PRIMARY KEY (id)
        , CONSTRAINT FK_DeduccionXMes_PlanillaMensual FOREIGN KEY (idPlanillaMensual) REFERENCES dbo.PlanillaMensual (id)
        , CONSTRAINT FK_DeduccionXMes_TipoDeduccion   FOREIGN KEY (idTipoDeduccion)   REFERENCES dbo.TipoDeduccion (id)
    );
END
GO

-- DEDUCCIONES POR EMPLEADO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DeduccionEmpleado' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.DeduccionEmpleado (
        id                INT            IDENTITY(1,1) NOT NULL
        , idEmpleado      INT            NOT NULL
        , idTipoDeduccion INT            NOT NULL
        , MontoFijo       DECIMAL(10,2)  NOT NULL CONSTRAINT DF_DeduccionEmpleado_MontoFijo  DEFAULT 0
        , FechaInicio     DATE           NOT NULL
        , FechaFin        DATE           NOT NULL CONSTRAINT DF_DeduccionEmpleado_FechaFin   DEFAULT '9999-12-31'
        , CONSTRAINT PK_DeduccionEmpleado PRIMARY KEY (id)
        , CONSTRAINT FK_DeduccionEmpleado_Empleado     FOREIGN KEY (idEmpleado)      REFERENCES dbo.Empleado (id)
        , CONSTRAINT FK_DeduccionEmpleado_TipoDeduccion FOREIGN KEY (idTipoDeduccion) REFERENCES dbo.TipoDeduccion (id)
    );
END
GO

-- TRAZABILIDAD Y ERRORES

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BitacoraEvento' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.BitacoraEvento (
        id              INT             IDENTITY(1,1) NOT NULL
        , idTipoEvento  INT             NOT NULL
        , idUsuario     INT             NOT NULL
        , FechaHora     DATETIME        NOT NULL CONSTRAINT DF_BitacoraEvento_FechaHora   DEFAULT GETUTCDATE()
        , IP            VARCHAR(45)     NOT NULL
        , Descripcion   NVARCHAR(2000)  NOT NULL CONSTRAINT DF_BitacoraEvento_Descripcion DEFAULT ''
        , CONSTRAINT PK_BitacoraEvento PRIMARY KEY (id)
        , CONSTRAINT FK_BitacoraEvento_TipoEvento FOREIGN KEY (idTipoEvento) REFERENCES dbo.TipoEvento (id)
        , CONSTRAINT FK_BitacoraEvento_Usuario    FOREIGN KEY (idUsuario)    REFERENCES dbo.Usuario (id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DBError' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.DBError (
        id              INT              IDENTITY(1,1) NOT NULL
        , UserName      NVARCHAR(128)    NOT NULL
        , Number        INT              NOT NULL
        , State         INT              NOT NULL
        , Severity      INT              NOT NULL
        , Line          INT              NOT NULL
        , [Procedure]   NVARCHAR(128)    NOT NULL CONSTRAINT DF_DBError_Procedure DEFAULT ''
        , Message       NVARCHAR(4000)   NOT NULL
        , DateTime      DATETIME         NOT NULL CONSTRAINT DF_DBError_DateTime  DEFAULT GETUTCDATE()
        , CONSTRAINT PK_DBError PRIMARY KEY (id)
    );
END
GO
