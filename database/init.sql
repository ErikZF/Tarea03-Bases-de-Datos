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

:r /scripts/StoredProcedures/Planilla/spAperturaSemana.sql
GO

:r /scripts/StoredProcedures/Planilla/spCierreSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spConsultarPlanillaSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spConsultarDeduccionesSemanal.sql
GO

:r /scripts/StoredProcedures/Planilla/spDetallePlanillaMensual.sql
GO


:r /scripts/StoredProcedures/Empleado/spInsertarEmpleado.sql
GO

:r /scripts/StoredProcedures/Empleado/spEliminarEmpleado.sql
GO

:r /scripts/StoredProcedures/Empleado/spActualizarEmpleado.sql
GO




--#####################################################################
-- TRIGGERS
--#####################################################################

:r /scripts/Trigger/triggerAsociarEmpleadoDeducciones.sql
GO


--#####################################################################
-- LLENAR CATALOGOS CON XML
--#####################################################################

:r /scripts/Data/spCargarCatalogosXML.sql
GO