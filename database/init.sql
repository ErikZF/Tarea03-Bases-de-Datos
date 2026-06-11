-- init.sql
-- Punto de entrada unico para inicializar DBPlanilla
-- Ejecutar desde la raiz de /scripts con:
--   sqlcmd -S localhost,1433 -U sa -P TuPassword123! -i init.sql

--#####################################################################
-- CREAR Y USAR DB
--#####################################################################

:r /scripts/Migrations/00_create_database.sql
GO

--#####################################################################
-- CREAR TABLAS (incluye DBError)
--#####################################################################

:r /scripts/Migrations/01_create_tables.sql
GO


--#####################################################################
-- STORED PROCEDURES
--#####################################################################



:r /scripts/StoredProcedures/Error/spInsertarError.sql
GO

:r /scripts/StoredProcedures/Error/spConsultarError.sql
GO

:r /scripts/StoredProcedures/Auth/spInsertarBitacoraEvento.sql
GO

:r /scripts/StoredProcedures/Planilla/spAperturaSemana.sql
GO

:r /scripts/StoredProcedures/Planilla/spCierreSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spConsultarPlanillaSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spConsultarPlanillaMensual.sql
GO

:r /scripts/StoredProcedures/Planilla/spConsultarDeduccionesSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spDetallePlanillaMensual.sql
GO

:r /scripts/StoredProcedures/Planilla/spDetallePlanillaSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spProcesarMarcaAsistencia.sql
GO




:r /scripts/StoredProcedures/Empleado/spListarEmpleados.sql
GO

:r /scripts/StoredProcedures/Empleado/spConsultarEmpleado.sql
GO

:r /scripts/StoredProcedures/Empleado/spObtenerPuestos.sql
GO

:r /scripts/StoredProcedures/Empleado/spInsertarEmpleado.sql
GO

:r /scripts/StoredProcedures/Empleado/spEliminarEmpleado.sql
GO

:r /scripts/StoredProcedures/Empleado/spActualizarEmpleado.sql
GO


:r /scripts/StoredProcedures/Auth/spLogin.sql
GO

:r /scripts/StoredProcedures/Auth/spLogout.sql
GO

--#####################################################################
-- TRIGGERS
--#####################################################################

:r /scripts/Trigger/triggerAsociarEmpleadoDeducciones.sql
GO

--#####################################################################
-- HABILITAR LECTURA DE ARCHIVOS EXTERNOS (OPENROWSET BULK)
--#####################################################################

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO


--#####################################################################
-- CARGAR CATALOGOS XML
--#####################################################################

:r /scripts/Data/spCargarCatalogosXML.sql
GO

DECLARE @outResultCodeCatalogos INT = 0;
EXEC dbo.spCargarCatalogosXML @outResultCode = 
@outResultCodeCatalogos OUTPUT;
SELECT @outResultCodeCatalogos AS [CodigoResultadoCatalogos];
GO

--#####################################################################
-- ETL DE OPERACIONES
--#####################################################################

:r /scripts/ETL/spETLCargaOperacionEmpleado.sql
GO

DECLARE @outResultCodeETL INT = 0;
DECLARE @ResultadoCodigo INT = 0

EXEC dbo.spETLCargaOperacionEmpleado
    @outResultCode = @ResultadoCodigo OUTPUT;


SELECT @ResultadoCodigo AS [CodigoResultadoETL];