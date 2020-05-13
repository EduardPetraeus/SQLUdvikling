DECLARE @publisher NVARCHAR(100)
DECLARE @cur_hostname NVARCHAR(100)
DECLARE @pubdb NVARCHAR(100)
DECLARE @pubname NVARCHAR(100)
DECLARE @desc NVARCHAR(255)
DECLARE @found INT

-- Naar 'sp_addpublication' oprettes med: @job_login = null, @job_password = null,
-- saettes: "Agent Security" til at vaere "SQL Server Agent account". 
-- Dette skal derefter rettes manuelt i en releaseopgave til at vaere en ServiceBruger.

SET @publisher = N'BMAT-LZSQL-P01'
SET @cur_hostname = HOST_NAME() COLLATE DATABASE_DEFAULT
IF @cur_hostname = @publisher
    BEGIN
        SET @pubdb = N'AES_ATP'
        SET @pubname = N'Pub_'+@pubdb
        SET @desc =  N'Snapshot publication of database ''' + @pubdb + ''' from Publisher '''+@publisher+'''.'
        EXEC [AES_ATP].[dbo].sp_helppublication @publication = @pubname, @found = @found OUTPUT
        IF ISNULL(@found, 0) = 0
        BEGIN
            EXEC sp_replicationdboption @dbname = @pubdb, @optname = N'publish', @value = N'true'
            EXEC [AES_ATP].[dbo].sp_addpublication @publication = @pubname, @description = @desc, @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'false', @alt_snapshot_folder = N'\\bmat-lzsql-p01.prod.sitad.dk\az_replication', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
            EXEC [AES_ATP].[dbo].sp_addpublication_snapshot @publication = @pubname, @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
        END
        EXEC [tempdb].[dbo].[AddArticlesLZ] @published_db = @pubdb, @published_pubname = @pubname;

        SET @pubdb = N'ATIS'
        SET @pubname = N'Pub_'+@pubdb
        SET @desc =  N'Snapshot publication of database ''' + @pubdb + ''' from Publisher '''+@publisher+'''.'
        EXEC [ATIS].[dbo].sp_helppublication @publication = @pubname, @found = @found OUTPUT
        IF ISNULL(@found, 0) = 0
        BEGIN
            EXEC sp_replicationdboption @dbname = @pubdb, @optname = N'publish', @value = N'true'
            EXEC [ATIS].[dbo].sp_addpublication @publication = @pubname, @description = @desc, @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'false', @alt_snapshot_folder = N'\\bmat-lzsql-p01.prod.sitad.dk\az_replication', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
            EXEC [ATIS].[dbo].sp_addpublication_snapshot @publication = @pubname, @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
        END
        EXEC [tempdb].[dbo].[AddArticlesLZ] @published_db = @pubdb, @published_pubname = @pubname;

        SET @pubdb = N'CPR'
        SET @pubname = N'Pub_'+@pubdb
        SET @desc =  N'Snapshot publication of database ''' + @pubdb + ''' from Publisher '''+@publisher+'''.'
        EXEC [CPR].[dbo].sp_helppublication @publication = @pubname, @found = @found OUTPUT
        IF ISNULL(@found, 0) = 0
        BEGIN
            EXEC sp_replicationdboption @dbname = @pubdb, @optname = N'publish', @value = N'true'
            EXEC [CPR].[dbo].sp_addpublication @publication = @pubname, @description = @desc, @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'false', @alt_snapshot_folder = N'\\bmat-lzsql-p01.prod.sitad.dk\az_replication', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
            EXEC [CPR].[dbo].sp_addpublication_snapshot @publication = @pubname, @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
        END
        EXEC [tempdb].[dbo].[AddArticlesLZ] @published_db = @pubdb, @published_pubname = @pubname;

        SET @pubdb = N'CVR'
        SET @pubname = N'Pub_'+@pubdb
        SET @desc =  N'Snapshot publication of database ''' + @pubdb + ''' from Publisher '''+@publisher+'''.'
        EXEC [CVR].[dbo].sp_helppublication @publication = @pubname, @found = @found OUTPUT
        IF ISNULL(@found, 0) = 0
        BEGIN
            EXEC sp_replicationdboption @dbname = @pubdb, @optname = N'publish', @value = N'true'
            EXEC [CVR].[dbo].sp_addpublication @publication = @pubname, @description = @desc, @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'false', @alt_snapshot_folder = N'\\bmat-lzsql-p01.prod.sitad.dk\az_replication', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
            EXEC [CVR].[dbo].sp_addpublication_snapshot @publication = @pubname, @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
        END
        EXEC [tempdb].[dbo].[AddArticlesLZ] @published_db = @pubdb, @published_pubname = @pubname;

        SET @pubdb = N'DAWA'
        SET @pubname = N'Pub_'+@pubdb
        SET @desc =  N'Snapshot publication of database ''' + @pubdb + ''' from Publisher '''+@publisher+'''.'
        EXEC [DAWA].[dbo].sp_helppublication @publication = @pubname, @found = @found OUTPUT
        IF ISNULL(@found, 0) = 0
        BEGIN
            EXEC sp_replicationdboption @dbname = @pubdb, @optname = N'publish', @value = N'true'
            EXEC [DAWA].[dbo].sp_addpublication @publication = @pubname, @description = @desc, @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'false', @alt_snapshot_folder = N'\\bmat-lzsql-p01.prod.sitad.dk\az_replication', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
            EXEC [DAWA].[dbo].sp_addpublication_snapshot @publication = @pubname, @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
        END
        EXEC [tempdb].[dbo].[AddArticlesLZ] @published_db = @pubdb, @published_pubname = @pubname;

        SET @pubdb = N'Direktionsrapportering'
        SET @pubname = N'Pub_'+@pubdb
        SET @desc =  N'Snapshot publication of database ''' + @pubdb + ''' from Publisher '''+@publisher+'''.'
        EXEC [Direktionsrapportering].[dbo].sp_helppublication @publication = @pubname, @found = @found OUTPUT
        IF ISNULL(@found, 0) = 0
        BEGIN
            EXEC sp_replicationdboption @dbname = @pubdb, @optname = N'publish', @value = N'true'
            EXEC [Direktionsrapportering].[dbo].sp_addpublication @publication = @pubname, @description = @desc, @sync_method = N'native', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'false', @alt_snapshot_folder = N'\\bmat-lzsql-p01.prod.sitad.dk\az_replication', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'snapshot', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1
            EXEC [Direktionsrapportering].[dbo].sp_addpublication_snapshot @publication = @pubname, @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
        END
        EXEC [tempdb].[dbo].[AddArticlesLZ] @published_db = @pubdb, @published_pubname = @pubname;
    END