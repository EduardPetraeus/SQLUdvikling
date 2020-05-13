-- References:
-- https://docs.microsoft.com/en-us/sql/relational-databases/replication/administration/distributor-and-publisher-information-script?view=sql-server-2017
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-changepublication-transact-sql?view=sql-server-2017
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addarticle-transact-sql?view=sql-server-2017
CREATE OR ALTER PROCEDURE [dbo].[AddArticlesDZ] @published_db NVARCHAR(100), @published_pubname NVARCHAR(100)
AS

SET NOCOUNT ON;

--Variables
DECLARE @sql NVARCHAR(max)
DECLARE @Archive_schema_id INT
DECLARE @C_ART CURSOR

DECLARE @TblArticles TABLE (
   [table_name] NVARCHAR(255),
   [schema_id] INT,
   [schema_name] NVARCHAR(255)
)

DECLARE @t_table_name SYSNAME
DECLARE @t_schema_id INT
DECLARE @t_schema_name SYSNAME

DECLARE @t_article_name SYSNAME
DECLARE @t_source_owner SYSNAME
DECLARE @t_source_object SYSNAME
DECLARE @t_type SYSNAME = N'logbased'
DECLARE @t_description NVARCHAR(255) = N''
DECLARE @t_creation_script NVARCHAR(255) = N''
DECLARE @t_pre_creation_cmd NVARCHAR(10) =  N'drop'
DECLARE @t_schema_option INT = NULL
DECLARE @t_identityrangemanagementoption NVARCHAR(10) =  NULL
DECLARE @t_destination_table SYSNAME
DECLARE @t_destination_owner SYSNAME
DECLARE @t_status TINYINT = 24
DECLARE @t_vertical_partition NVARCHAR(10) = N'false'
DECLARE @t_ins_cmd NVARCHAR(255) = N'SQL'
DECLARE @t_del_cmd NVARCHAR(255) = N'SQL'
DECLARE @t_upd_cmd NVARCHAR(255) = N'SQL'

DECLARE @sqlpars nvarchar(max)
set @sqlpars = N'
@i_published_pubname NVARCHAR(100),
@i_t_article_name SYSNAME,
@i_t_source_owner SYSNAME,
@i_t_source_object SYSNAME,
@i_t_type SYSNAME,
@i_t_description NVARCHAR(255),
@i_t_creation_script NVARCHAR(255),
@i_t_pre_creation_cmd NVARCHAR(10),
@i_t_schema_option INT,
@i_t_identityrangemanagementoption NVARCHAR(10),
@i_t_destination_table SYSNAME,
@i_t_destination_owner SYSNAME,
@i_t_status TINYINT,
@i_t_vertical_partition NVARCHAR(10),
@i_t_ins_cmd NVARCHAR(255),
@i_t_del_cmd NVARCHAR(255),
@i_t_upd_cmd NVARCHAR(255)
'

--Find alle tabeller
PRINT 'DZ: Tilføjer artikler for database: "' + @published_db + '" og publicering: "' + @published_pubname + '"'
PRINT ''
set @sql = 'SELECT STABLES.[name] AS [table_name], STABLES.[schema_id] AS [schema_id], SSCHEMAS.[name] AS [schema_name] ' + 
'FROM ' + quotename(@published_db) + '.sys.tables STABLES JOIN ' + quotename(@published_db) + '.sys.schemas SSCHEMAS ' + 
'ON (STABLES.[schema_id] = SSCHEMAS.[schema_id]) ' + 
'WHERE STABLES.[is_ms_shipped] != 1 ORDER BY [table_name]'
DELETE @TblArticles
INSERT INTO @TblArticles EXEC (@sql)

SET @C_ART = CURSOR FOR
SELECT * FROM @TblArticles

OPEN @C_ART
FETCH NEXT
FROM @C_ART INTO @t_table_name, @t_schema_id, @t_schema_name

WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @t_article_name = @t_schema_name + '_' +  @t_table_name
        SET @t_source_owner = @t_schema_name
        SET @t_source_object = @t_table_name
        SET @t_destination_table = @t_table_name
        SET @t_destination_owner = @t_schema_name
        --PRINT @t_table_name + ' ' + CAST(@t_schema_id AS VARCHAR)  + ' ' + @t_schema_name + ' ' + @t_article_name
        set @sql = quotename(@published_db) + '.[dbo].sp_addarticle'+
            ' @publication=@i_published_pubname'+
            ', @article=@i_t_article_name'+
            ', @source_owner=@i_t_source_owner'+
            ', @source_object=@i_t_source_object'+
            ', @type=@i_t_type'+
            ', @description=@i_t_description'+
            ', @creation_script=@i_t_creation_script'+
            ', @pre_creation_cmd=@i_t_pre_creation_cmd'+
            ', @schema_option=@i_t_schema_option'+
            ', @identityrangemanagementoption=@i_t_identityrangemanagementoption'+
            ', @destination_table=@i_t_destination_table'+
            ', @destination_owner=@i_t_destination_owner'+
            ', @status=@i_t_status'+
            ', @vertical_partition=@i_t_vertical_partition'+
            ', @ins_cmd=@i_t_ins_cmd'+
            ', @del_cmd=@i_t_del_cmd'+
            ', @upd_cmd=@i_t_upd_cmd'

        --PRINT (@sql)
        EXEC sp_executesql @sql, @sqlpars,  
            @i_published_pubname=@published_pubname,
            @i_t_article_name=@t_article_name,
            @i_t_source_owner=@t_source_owner,
            @i_t_source_object=@t_source_object,
            @i_t_type=@t_type,
            @i_t_description=@t_description,
            @i_t_creation_script=@t_creation_script,
            @i_t_pre_creation_cmd=@t_pre_creation_cmd,
            @i_t_schema_option=@t_schema_option,
            @i_t_identityrangemanagementoption=@t_identityrangemanagementoption,
            @i_t_destination_table=@t_destination_table,
            @i_t_destination_owner=@t_destination_owner,
            @i_t_status=@t_status,
            @i_t_vertical_partition=@t_vertical_partition,
            @i_t_ins_cmd=@t_ins_cmd,
            @i_t_del_cmd=@t_del_cmd,
            @i_t_upd_cmd=@t_upd_cmd;

        FETCH NEXT
        FROM @C_ART INTO @t_table_name, @t_schema_id, @t_schema_name
    END

SET NOCOUNT OFF;