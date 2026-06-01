-- init.sql
-- Punto de entrada unico para inicializar DBPlanilla
-- Ejecutar desde la raiz de /scripts con:
--   sqlcmd -S localhost,1433 -U sa -P TuPassword123! -i init.sql

--#####################################################################
-- CREAR Y USAR DB
--#####################################################################

:r /scripts/migrations/00_create_database.sql


--#####################################################################
-- CREAR TABLAS (incluye DBError)
--#####################################################################

:r /scripts/migrations/01_create_tables.sql


--#####################################################################
-- STORED PROCEDURES
--#####################################################################

:r /scripts/stored_procedure/spInsertarError.sql
:r /scripts/data/spCargarCatalogosXML.sql


--#####################################################################
-- TRIGGERS
--#####################################################################

:r /scripts/Trigger/triggerAsociarEmpleadoDeducciones.sql


--#####################################################################
-- LLENAR CATALOGOS CON XML
--#####################################################################

EXEC dbo.spCargarCatalogosXML;
GO
