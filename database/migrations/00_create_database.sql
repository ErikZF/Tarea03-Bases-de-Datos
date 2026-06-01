-- 00_create_database.sql
-- Crea la base de datos si no existe

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DBPlanilla')
BEGIN
    CREATE DATABASE DBPlanilla;
END
GO

USE DBPlanilla;
GO
