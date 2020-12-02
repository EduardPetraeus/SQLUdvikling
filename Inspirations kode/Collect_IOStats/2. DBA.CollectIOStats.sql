USE [msdb]
GO

DECLARE 
	@ReturnCode INT
	,@v_Database NVARCHAR(100)
	,@v_OwnerLoginName NVARCHAR(50)	
	,@v_JobName NVARCHAR(200) 
;

DECLARE 
	@v_JobId BINARY(16)
	,@v_JobIdText NVARCHAR(50)
;

SET @v_Database = N'Maintenance'
SET @v_OwnerLoginName = N'sa'
SET @v_JobName = 'DBA.CollectIOStats'
;

SET @v_JobIdText = (SELECT TOP 1 job_id FROM [dbo].[sysjobs_view] WHERE [name] = @v_JobName)
;

-- Delete Job if exists
IF @v_JobIdText IS NOT NULL
	EXEC msdb.dbo.sp_delete_job @job_id=@v_JobIdText, @delete_unused_schedule=1
;

BEGIN TRANSACTION

SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@v_JobName, 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This Job collects IO Stats', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@v_OwnerLoginName, @job_id = @v_JobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@v_JobId, @step_name=@v_JobName, 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON
;
DECLARE @i INT = 1
;

WHILE (@i <= 5) 
BEGIN

	DROP TABLE IF EXISTS #IOStats
	;

	CREATE TABLE #IOStats (
			   [Sampling] int,
			   [SampleTime] datetime default getdate(),
			   [database_name] [nvarchar](128),
			   [DatabaseFilename] [nvarchar](260),
			   [io_stall_read_ms] [bigint],
			   [io_stall_write_ms] [bigint],
			   [num_of_reads] [bigint],
			   [num_of_bytes_read] [bigint],
			   [num_of_writes] [bigint],
			   [num_of_bytes_written] [bigint]
	)

	--Indsætter første IO sampling i tabellen
	INSERT INTO #IOStats
	SELECT 
			   1
			   , GETDATE()
			   ,DB_NAME(vfs.database_id)
			   , mf.physical_name
			   , io_stall_read_ms 
			   , io_stall_write_ms
			   , vfs.num_of_reads
			   , vfs.num_of_bytes_read
			   , vfs.num_of_writes
			   , vfs.num_of_bytes_written
	FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
	INNER JOIN 
	sys.master_files AS mf 
	ON vfs.database_id = mf.database_id AND vfs.FILE_ID = mf.FILE_ID
	;

	WAITFOR DELAY ''00:01:00''
	;

	INSERT INTO #IOStats
	SELECT 
			   2
			   ,GETDATE()
			   ,DB_NAME(vfs.database_id)
			   , mf.physical_name
			   , io_stall_read_ms 
			   , io_stall_write_ms
			   , vfs.num_of_reads
			   , vfs.num_of_bytes_read
			   , vfs.num_of_writes
			   , vfs.num_of_bytes_written
	FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
	INNER JOIN 
	sys.master_files AS mf 
	ON (vfs.database_id = mf.database_id AND vfs.FILE_ID = mf.FILE_ID)
	;

	WITH CTE AS (

			SELECT 
			   DATEDIFF(SS, t1.SampleTime, t2.SampleTime) AS SamplingDurationSec,
			   t1.SampleTime as StartTime,
			   t2.SampleTime as EndTime,
			   t1.database_name,
			   t1.DatabaseFilename,
			   t2.io_stall_read_ms-t1.io_stall_read_ms as io_stall_read_ms_diff,
			   t2.io_stall_write_ms-t1.io_stall_write_ms as io_stall_write_ms_diff,
			   t2.num_of_reads-t1.num_of_reads as num_of_reads_diff,
			   t2.num_of_writes-t1.num_of_writes as num_of_writes_diff,
			   CAST((t2.num_of_reads-t1.num_of_reads)*1./DATEDIFF(ss, t1.SampleTime, t2.SampleTime) as decimal(10,2)) as num_of_reads_per_sec,
			   CAST((t2.num_of_writes-t1.num_of_writes)*1./DATEDIFF(ss, t1.SampleTime, t2.SampleTime) as decimal(10,2))as num_of_writes_per_sec,
			   CAST((t2.num_of_bytes_read-t1.num_of_bytes_read)/1000/DATEDIFF(ss, t1.SampleTime, t2.SampleTime) as decimal(10,2))as num_of_KBytes_read_per_sec,
			   CAST((t2.num_of_bytes_written-t1.num_of_bytes_written)/1000/DATEDIFF(ss, t1.SampleTime, t2.SampleTime) as decimal(10,2))as num_of_KBytes_written_per_sec
			FROM 
			   #IOStats t1
			   INNER JOIN 
			   #IOStats t2 
			   ON (t1.DatabaseFilename = t2.DatabaseFilename and t1.Sampling = 1 and t2.Sampling = 2)
	) 

	INSERT INTO [dbo].[IOStats]
	SELECT
		StartTime,
		EndTime,
		database_name,
		DatabaseFilename,
		num_of_reads_diff as Reads,
		num_of_writes_diff as Writres,
		num_of_reads_per_sec as ReadsPerSec,
		num_of_writes_per_sec as WritesPerSec,
		num_of_KBytes_read_per_sec as ReadKBPerSec,
		CASE WHEN num_of_reads_per_sec = 0 THEN NULL ELSE CAST(num_of_KBytes_read_per_sec/num_of_reads_per_sec AS DECIMAL(10,2)) END as KBPerRead,
		CASE WHEN num_of_writes_per_sec = 0 THEN NULL ELSE CAST(num_of_KBytes_written_per_sec/num_of_writes_per_sec AS DECIMAL(10,2)) END as KBPerWrite,
		num_of_KBytes_written_per_sec as WriteKBPerSec,
		CASE WHEN num_of_reads_diff = 0 THEN NULL ELSE io_stall_read_ms_diff/num_of_reads_diff END AS AvgReadLatencyMs,
		CASE WHEN num_of_writes_diff = 0 THEN NULL ELSE io_stall_write_ms_diff/num_of_writes_diff END AS AvgWriteLatencyMs
	FROM CTE
	;

	SET @i = @i + 1
	;

END', 
		@database_name=@v_Database, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @v_JobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@v_JobId, @name=N'CollectIOStats30Min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20200604, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'ff4e7d55-e3eb-495b-9c96-13819d317c36'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@v_JobId, @name=N'CollectIOStatsDaily', 
		@enabled=0, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20200604, 
		@active_end_date=99991231, 
		@active_start_time=90000, 
		@active_end_time=235959, 
		@schedule_uid=N'c5c05149-f07e-4fef-897e-b8e8a21a5457'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @v_JobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


