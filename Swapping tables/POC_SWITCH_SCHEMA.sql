USE [Sandbox]
GO

IF SCHEMA_ID('swap') IS NULL
	EXECUTE('CREATE SCHEMA [swap]')
;

IF SCHEMA_ID('prev') IS NULL
	EXECUTE('CREATE SCHEMA [prev]')
;

--BEGIN TRAN;

DROP TABLE IF EXISTS [prev].[TableProd], [dbo].[TableProd], [swap].[TableProd], [dbo].[Table_staging], [swap].[Table_staging],  [dbo].[TableProd_Prev]
; 

CREATE TABLE [dbo].[TableProd]
  (
     Name1 NVARCHAR(1000) INDEX NCI_Name,
     Created   DATETIME INDEX NCI_Created 
  );


CREATE TABLE [swap].[TableProd]
  (
     Name1 NVARCHAR(100) INDEX NCI_Name,
     Created   DATETIME INDEX NCI_Created 
  );


INSERT INTO [dbo].[TableProd]
VALUES      ('Group3',GETDATE())
;

INSERT INTO [swap].[TableProd]
VALUES      ('Group1',GETDATE()),
            ('Group2',GETDATE())
;

ALTER INDEX NCI_Name ON [swap].[TableProd] REBUILD
;
ALTER INDEX NCI_Created ON [swap].[TableProd] REBUILD
;

-- Switch data from production table into production previous table
ALTER SCHEMA [prev] TRANSFER [dbo].[TableProd]
;

ALTER SCHEMA [dbo] TRANSFER [swap].[TableProd]
;

SELECT object_id,
       '[prev].[TableProd]' AS table_name, 
       index_id,
       allocated_page_file_id,
       allocated_page_page_id
FROM   sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID('[prev].[TableProd]'), NULL, NULL, 'DETAILED')
WHERE  is_allocated = 1
; 

SELECT object_id,
       '[dbo].[TableProd]' AS table_name, 
       index_id,
       allocated_page_file_id,
       allocated_page_page_id
FROM   sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID('[dbo].[TableProd]'), NULL, NULL, 'DETAILED')
WHERE  is_allocated = 1
; 

SELECT *
FROM [dbo].[TableProd]
;

SELECT *
FROM [prev].[TableProd]
;

--COMMIT;