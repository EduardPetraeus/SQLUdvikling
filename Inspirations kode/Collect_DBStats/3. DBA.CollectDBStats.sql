USE [msdb]
GO

-- Declare Generel Variables
DECLARE 
	@ReturnCode INT
	,@v_Database NVARCHAR(100)
	,@v_JobName NVARCHAR(200) 
	,@v_OwnerLoginName NVARCHAR(50)	

;

DECLARE 
	@v_JobId BINARY(16)
	,@v_JobIdText NVARCHAR(50)
;

SET @v_Database = N'Maintenance'
SET @v_OwnerLoginName = N'sa'
SET @v_JobName = 'DBA.CollectDBStats'
;

SET @v_JobIdText = (SELECT TOP 1 job_id FROM [dbo].[sysjobs_view] WHERE [name] = @v_JobName)
;

-- Delete Job if exists
IF @v_JobIdText IS NOT NULL
	EXEC msdb.dbo.sp_delete_job @job_id=@v_JobIdText, @delete_unused_schedule=1
;

BEGIN TRANSACTION

SET @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@v_JobName, 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This Job collects DB Stats', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@v_OwnerLoginName, 
		@job_id = @v_JobId OUTPUT
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
		@command=N'--Truncate table [dbo].[dbStats]
		--;

SET NOCOUNT ON;
DECLARE
	@v_Sql NVARCHAR(1000)
   ,@i INT
;
SET @i = 1
;

SET @v_Sql = ''Use [?];
Insert into [Maintenance].[dbo].[temp_dbStats] (
   	[TimeSampled],
	[DataBaseName], 
	[DataSpaceType],
	[SizeGB], 
    [UsedGB], 
	[FreeGB], 
   	[PcntUsed], 
	[PcntFree]
  	)
Select
   	getdate(), 
	db_name(), 
	IIF([type_desc] = ''''ROWS'''', ''''DATA'''', [type_desc]),
	CAST(SUM([size]/(128.0*1024.0)) As Decimal(10,2)), 
	CAST(SUM(Fileproperty([name], ''''SpaceUsed'''')/(128.0*1024.0)) As Decimal(10,2)),
	NULL,
	NULL,
	NULL
From sys.database_files 
GROUP BY [type_desc]
;''

WHILE (@i <= 5) 
BEGIN

	TRUNCATE TABLE [dbo].[temp_dbStats]
	;
	EXEC sp_MSforeachdb @v_Sql
	;
	UPDATE D
	SET	
		[FreeGB] = [SizeGB] - [UsedGB],	
		[PcntUsed] = ([UsedGB]/(IIF([SizeGB]=0,1,[SizeGB])))*100,
		[PcntFree] = (([SizeGB]-[UsedGB])/(IIF([SizeGB]=0,1,[SizeGB])))*100
	FROM [Maintenance].[dbo].[temp_dbStats] D
	;

	INSERT INTO [dbo].[dbStats]
	SELECT * FROM [dbo].[temp_dbStats]
	;

	WAITFOR DELAY ''00:01:00''
	;

	SET @i = @i + 1
	;

END', 
		@database_name=@v_Database, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @v_JobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@v_JobId, @name=N'CollectDBStats30min', 
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
		@schedule_uid=N'78604d07-b577-4ee1-a660-43c4189b3ca0'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@v_JobId, @name=N'CollectDBStatsDaily', 
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
		@schedule_uid=N'5c5221e1-7ff0-45c5-aaad-61319190a794'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @v_JobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


