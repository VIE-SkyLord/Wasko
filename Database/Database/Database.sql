IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Wasko')
BEGIN
    DROP DATABASE Wasko;
END
GO

CREATE DATABASE Wasko;
GO

USE Wasko;
GO