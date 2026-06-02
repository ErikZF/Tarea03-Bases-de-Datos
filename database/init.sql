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
GO


--#####################################################################
-- STORED PROCEDURES
--#####################################################################

:r /scripts/stored_procedure/spInsertarError.sql
GO

:r /scripts/data/spCargarCatalogosXML.sql
GO


--#####################################################################
-- TRIGGERS
--#####################################################################

:r /scripts/Trigger/triggerAsociarEmpleadoDeducciones.sql
GO


--#####################################################################
-- LLENAR CATALOGOS CON XML
--#####################################################################

DECLARE @rc INT;
EXEC dbo.spCargarCatalogosXML @outResultCode = @rc OUTPUT;
PRINT 'spCargarCatalogosXML result: ' + CAST(@rc AS VARCHAR);
GO
