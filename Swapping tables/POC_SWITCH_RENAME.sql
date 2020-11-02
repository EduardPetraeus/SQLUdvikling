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

CREATE TABLE [dbo].[Table_staging]
  (
     Name1 NVARCHAR(100) INDEX NCI_Name,
     Created   DATETIME INDEX NCI_Created 
  );


INSERT INTO [dbo].[TableProd]
VALUES      ('Group3',GETDATE())
;

INSERT INTO [dbo].[Table_staging]
VALUES      ('Group1',GETDATE()),
            ('Group2',GETDATE())
;

ALTER INDEX NCI_Name ON [dbo].[Table_staging] REBUILD
;
ALTER INDEX NCI_Created ON [dbo].[Table_staging] REBUILD
;

SELECT object_id,
       '[dbo].[Table_staging]' AS table_name, 
       index_id,
       allocated_page_file_id,
       allocated_page_page_id
FROM   sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID('[dbo].[Table_staging]'), NULL, NULL, 'DETAILED')
WHERE  is_allocated = 1
; 

-- Switch data from production table into production previous table
EXEC sp_rename [TableProd], [TableProd_Prev]
;
-- Switch data from staging-table into production table
EXEC sp_rename [Table_staging], [TableProd]
;
-- Switch data from production previous table from into staging-table 
EXEC sp_rename [TableProd_Prev], [Table_staging]
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
FROM [dbo].[Table_staging]
;

--COMMIT;