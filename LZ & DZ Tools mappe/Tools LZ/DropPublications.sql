-- References:
-- https://docs.microsoft.com/en-us/sql/relational-databases/replication/administration/distributor-and-publisher-information-script?view=sql-server-2017
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-changepublication-transact-sql?view=sql-server-2017
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-dropsubscription-transact-sql?view=sql-server-2017
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-droparticle-transact-sql?view=sql-server-2017
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-droppublication-transact-sql?view=sql-server-2017
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-replicationdboption-transact-sql?view=sql-server-2017

SET NOCOUNT ON;

--Variables
DECLARE @published_db NVARCHAR(100)
DECLARE @published_pubid INT
DECLARE @published_pubname NVARCHAR(100)
DECLARE @C_DB CURSOR
DECLARE @C_PUB CURSOR
DECLARE @C_ART CURSOR

DECLARE @sql NVARCHAR(255)

DECLARE @TblPublications TABLE (
    [pubid] INT,
    [name] SYSNAME,
    [restricted] INT,
    [status] TINYINT,
    [task] INT,
    [replication frequency] TINYINT,
    [synchronization method] TINYINT,
    [description] NVARCHAR(255),
    [immediate_sync] BIT,
    [enabled_for_internet] BIT,
    [allow_push] BIT,
    [allow_pull] BIT,
    [allow_anonymous] BIT,
    [independent_agent] BIT,
    [immediate_sync_ready] BIT,
    [allow_sync_tran] BIT,
    [autogen_sync_procs] BIT,
    [snapshot_jobid] INT,
    [retention] INT,
    [has subscription] BIT,
    [allow_queued_tran] BIT,
    [snapshot_in_defaultfolder] BIT,
    [alt_snapshot_folder] NVARCHAR(255),
    [pre_snapshot_script] NVARCHAR(255),
    [post_snapshot_script] NVARCHAR(255),
    [compress_snapshot] BIT,
    [ftp_address] NVARCHAR(255),
    [ftp_port] INT,
    [ftp_subdirectory] NVARCHAR(255),
    [ftp_login] SYSNAME,
    [allow_dts] BIT,
    [allow_subscription_copy] BIT,
    [centralized_conflicts] BIT,
    [conflict_retention] INT,
    [conflict_policy] INT,
    [queue_type] NVARCHAR(255),
    [backward_comp_level] INT,
    [publish_to_AD] BIT,
    [allow_initialize_from_backup] BIT,
    [replicate_ddl] INT,
    [enabled_for_p2p] INT,
    [publish_local_changes_only] INT,
    [enabled_for_het_sub] INT,
    [enabled_for_p2p_conflictdetection] INT,
    [originator_id] INT,
    [p2p_continue_onconflict] INT,
    [allow_partition_switch] INT,
    [replicate_partition_switch] INT,
    [allow_drop] INT
)

DECLARE @TblArticles TABLE (
   [article id] INT,
   [article name] SYSNAME,
   [base object] NVARCHAR(257),
   [destination object] SYSNAME,
   [synchronization object] NVARCHAR(257),
   [type] SMALLINT,
   [status] TINYINT,
   [filter] NVARCHAR(257),
   [description] NVARCHAR(255),
   [insert_command] NVARCHAR(255),
   [update_command] NVARCHAR(255),
   [delete_command] NVARCHAR(255),
   [creation script path] NVARCHAR(255),
   [vertical partition] BIT,
   [pre_creation_cmd] TINYINT,
   [filter_clause] NVARCHAR(MAX),
   [schema_option] INT,
   [dest_owner] SYSNAME,
   [source_owner] SYSNAME,
   [unqua_source_object] SYSNAME,
   [sync_object_owner] SYSNAME,
   [unqualified_sync_object] SYSNAME,
   [filter_owner] NVARCHAR(255),
   [unqua_filter] NVARCHAR(255),
   [auto_identity_range] INT,
   [publisher_identity_range] INT,
   [identity_range] BIGINT,
   [threshold] BIGINT,
   [identityrangemanagementoption] INT,
   [fire_triggers_on_snapshot] INT
)

DECLARE @t_article_id INT
DECLARE @t_article_name SYSNAME
DECLARE @t_base_object NVARCHAR(257)
DECLARE @t_destination_object SYSNAME
DECLARE @t_synchronization_object NVARCHAR(257)
DECLARE @t_type SMALLINT
DECLARE @t_status TINYINT
DECLARE @t_filter NVARCHAR(257)
DECLARE @t_description NVARCHAR(255)
DECLARE @t_insert_command NVARCHAR(255)
DECLARE @t_update_command NVARCHAR(255)
DECLARE @t_delete_command NVARCHAR(255)
DECLARE @t_creation_script_path NVARCHAR(255)
DECLARE @t_vertical_partition BIT
DECLARE @t_pre_creation_cmd TINYINT
DECLARE @t_filter_clause NVARCHAR(MAX)
DECLARE @t_schema_option INT
DECLARE @t_dest_owner SYSNAME
DECLARE @t_source_owner SYSNAME
DECLARE @t_unqua_source_object SYSNAME
DECLARE @t_sync_object_owner SYSNAME
DECLARE @t_unqualified_sync_object SYSNAME
DECLARE @t_filter_owner NVARCHAR(255)
DECLARE @t_unqua_filter NVARCHAR(255)
DECLARE @t_auto_identity_range INT
DECLARE @t_publisher_identity_range INT
DECLARE @t_identity_range BIGINT
DECLARE @t_threshold BIGINT
DECLARE @t_identityrangemanagementoption INT
DECLARE @t_fire_triggers_on_snapshot INT

--Which databases are published using snapshot replication or transactional replication?  
SET @C_DB = CURSOR FOR
SELECT name FROM sys.databases WHERE is_published = 1;

OPEN @C_DB
FETCH NEXT
FROM @C_DB INTO @published_db
WHILE @@FETCH_STATUS = 0
    BEGIN
        --What are the snapshot and transactional publications in this database?
        set @sql = quotename(@published_db) + '.[dbo].sp_helppublication'
        DELETE @TblPublications
        INSERT INTO @TblPublications EXEC (@sql)

        SET @C_PUB = CURSOR FOR
        SELECT pubid, name AS pubname FROM @TblPublications;

        OPEN @C_PUB
        FETCH NEXT
        FROM @C_PUB INTO @published_pubid, @published_pubname
        WHILE @@FETCH_STATUS = 0
            BEGIN
                PRINT 'Dropping publications for: ' + @published_db + ' | "' + @published_pubname + '"'
                --What are the articles in snapshot and transactional publications in this database?
                set @sql = quotename(@published_db) + '.[dbo].sp_helparticle @publication=' + quotename(@published_pubname)

                DELETE @TblArticles
                INSERT INTO @TblArticles EXEC (@sql)

                SET @C_ART = CURSOR FOR
                SELECT * FROM @TblArticles

                OPEN @C_ART
                FETCH NEXT
                FROM @C_ART INTO @t_article_id,
                    @t_article_name,
                    @t_base_object,
                    @t_destination_object,
                    @t_synchronization_object,
                    @t_type,
                    @t_status,
                    @t_filter,
                    @t_description,
                    @t_insert_command,
                    @t_update_command,
                    @t_delete_command,
                    @t_creation_script_path,
                    @t_vertical_partition,
                    @t_pre_creation_cmd,
                    @t_filter_clause,
                    @t_schema_option,
                    @t_dest_owner,
                    @t_source_owner,
                    @t_unqua_source_object,
                    @t_sync_object_owner,
                    @t_unqualified_sync_object,
                    @t_filter_owner,
                    @t_unqua_filter,
                    @t_auto_identity_range,
                    @t_publisher_identity_range,
                    @t_identity_range,
                    @t_threshold,
                    @t_identityrangemanagementoption,
                    @t_fire_triggers_on_snapshot
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        --PRINT @published_db+' '+ CONVERT(NVARCHAR, @published_pubid)+' '+@published_pubname+' '+CONVERT(NVARCHAR, @t_article_id)+' '+@t_article_name
                        set @sql = quotename(@published_db) + '.[dbo].sp_dropsubscription @publication='+quotename(@published_pubname)+', @article='+quotename(@t_article_name)+', @subscriber = N''all'', @destination_db = N''all'''
                        EXEC (@sql)
                        set @sql = quotename(@published_db) + '.[dbo].sp_droparticle @publication='+quotename(@published_pubname)+', @article='+quotename(@t_article_name)+', @force_invalidate_snapshot=1'
                        EXEC (@sql)

                        FETCH NEXT
                        FROM @C_ART INTO @t_article_id,
                            @t_article_name,
                            @t_base_object,
                            @t_destination_object,
                            @t_synchronization_object,
                            @t_type,
                            @t_status,
                            @t_filter,
                            @t_description,
                            @t_insert_command,
                            @t_update_command,
                            @t_delete_command,
                            @t_creation_script_path,
                            @t_vertical_partition,
                            @t_pre_creation_cmd,
                            @t_filter_clause,
                            @t_schema_option,
                            @t_dest_owner,
                            @t_source_owner,
                            @t_unqua_source_object,
                            @t_sync_object_owner,
                            @t_unqualified_sync_object,
                            @t_filter_owner,
                            @t_unqua_filter,
                            @t_auto_identity_range,
                            @t_publisher_identity_range,
                            @t_identity_range,
                            @t_threshold,
                            @t_identityrangemanagementoption,
                            @t_fire_triggers_on_snapshot
                    END
                -- Skal kun udfores hvis publicationen helt skal droppes.
                --set @sql = quotename(@published_db) + '.[dbo].sp_droppublication @publication='+quotename(@published_pubname)
                --EXEC (@sql)
                FETCH NEXT
                FROM @C_PUB INTO @published_pubid, @published_pubname

            CLOSE @C_ART
            DEALLOCATE @C_ART
            END

        -- Skal kun udfores hvis publicationen helt skal droppes.
        --set @sql = 'master.[dbo].sp_replicationdboption @dbname='+quotename(@published_db)+', @optname=N''publish'', @value = N''false'''
        --EXEC (@sql)
        FETCH NEXT
        FROM @C_DB INTO @published_db

    CLOSE @C_PUB
    DEALLOCATE @C_PUB
    END

CLOSE @C_DB
DEALLOCATE @C_DB

SET NOCOUNT OFF;