USE [msdb]
GO

CREATE OR ALTER PROCEDURE #ref_id (
	@folder SYSNAME,
	@project SYSNAME
)
AS
BEGIN
	SELECT CAST(reference_id AS NVARCHAR(10))
	FROM SSISDB.catalog.environment_references a
	INNER JOIN SSISDB.catalog.projects b
		ON a.project_id = b.project_id
	INNER JOIN SSISDB.catalog.folders c
		ON b.folder_id = c.folder_id
	WHERE c.name = @folder
		AND b.name = @project
		AND a.environment_name = @project
END
GO

DECLARE @ref TABLE(id NVARCHAR(10))

DECLARE @jobName NVARCHAR(100) = N'Staging - Dimension'
DECLARE @message NVARCHAR(100) = N'Setting up agent job ''' + @jobName + N''''
RAISERROR (@message, 0, 1) WITH NOWAIT

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Landing Zone' AND category_class=1)	BEGIN
	RAISERROR (N'Creating category ''Landing Zone''', 0, 1) WITH NOWAIT
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Landing Zone'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

DECLARE @jobId BINARY(16)
DECLARE @newJob INT = 0

--


SELECT @jobId = job_id
FROM msdb.dbo.sysjobs_view
WHERE name = @jobName

IF @jobId IS NULL BEGIN
	SET @newJob = 1
	SET @message = 'Creating job ''' + @jobName + ''''
	RAISERROR (@message, 0, 1) WITH NOWAIT
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@jobName, 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'Loader Dimensionstabeller fra Archive til Staging', 
			@category_name=N'Landing Zone', 
			@job_id = @jobId OUTPUT

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

-- Remove all existing steps
DECLARE @stepCount INTEGER
SELECT @stepCount = COUNT(*) FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId
WHILE @stepCount > 0
BEGIN
	EXEC msdb.dbo.sp_delete_jobstep @job_id = @jobId, @step_id = @stepCount
	SET @stepCount = @stepCount - 1
END


DECLARE	@go_to_next_step INT = 3
DECLARE @quit_job_reporting_failure INT = 2
DECLARE @quit_with_success INT = 1
DECLARE @stepName nvarchar(100)
SET @message = N'Creating job step ''' + @stepName + ''''
RAISERROR (@message, 0, 1) WITH NOWAIT

DECLARE @command NVARCHAR(MAX) 

-- Step 1: K�r SSIS pakke Master_Dimension

SET @stepName = N'Master Staging - Dimension' 

DELETE @ref
INSERT INTO @ref(id) EXECUTE #ref_id @folder = N'Datawarehouse', @project = N'Staging'

SET @command = CONCAT(
	N'/ISSERVER "\"\SSISDB\Datawarehouse\Staging\Master Staging Dimension.dtsx\"" /SERVER "\"',
	@@servername,
	N'\""',
	N' /ENVREFERENCE ' + (SELECT id FROM @ref),
	N' /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E')

SET @message = N'Creating job step ''' + @stepName + ''''
RAISERROR (@message, 0, 1) WITH NOWAIT

EXEC msdb.dbo.sp_add_jobstep
		@job_id = @jobId,
		@step_name = @stepName, 
		@cmdexec_success_code = 0, 
		@on_success_action = @go_to_next_step,
		@on_fail_action = @quit_job_reporting_failure,
		@retry_attempts = 0, 
		@retry_interval = 0, 
		@os_run_priority = 0,
		@subsystem = N'SSIS', 
		@command = @command,
		@server = @@servername, 
		@database_name = N'master', 
		@flags = 0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Step 2: Trigger SQL Agent Job: DM - Dimension

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Trigger job: DMSA - Dimension', 
		@cmdexec_success_code = 0, 
		@on_success_action = @quit_with_success,
		@on_success_step_id = 0, 
		@on_fail_action = @quit_job_reporting_failure, 
		@on_fail_step_id = 0, 
		@retry_attempts = 0, 
		@retry_interval = 0, 
		@os_run_priority = 0, @subsystem=N'TSQL', 
		@command=N'EXECUTE (N''EXEC msdb.dbo.sp_start_job @job_name = ''''DMSA - Dimension'''', @step_name=''''Master DMSA Dimension'''''')
		IF (@@ERROR <> 0) RAISERROR (''Failed to start agent job in Distribution Zone'',16,1)
		', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

RAISERROR ('Updating job', 0, 1) WITH NOWAIT
EXEC @ReturnCode = msdb.dbo.sp_update_job
	@job_id = @jobId,
	@start_step_id = 1, 
	@notify_level_email = 2, 
	@category_name = N'Landing Zone'
	
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Step 4: Remove all existing schedules
DECLARE @scheduleId INTEGER
SELECT TOP(1) @scheduleId = schedule_id FROM msdb.dbo.sysjobschedules WHERE job_id = @jobId
WHILE @scheduleId IS NOT NULL
BEGIN
    EXECUTE msdb.dbo.sp_detach_schedule @job_id = @jobId, @schedule_id = @scheduleId, @delete_unused_schedule = 1
    SET @scheduleId = NULL
    SELECT TOP(1) @scheduleId = schedule_id FROM msdb.dbo.sysjobschedules WHERE job_id = @jobId
END


IF @newJob = 1 BEGIN
	RAISERROR ('Assigning job to server', 0, 1) WITH NOWAIT
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
	RAISERROR ('Something went wrong. Rolling back.', 0, 1) WITH NOWAIT
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
RAISERROR ('All done', 0, 1) WITH NOWAIT
GO
