USE [msdb]
GO

CREATE PROCEDURE #ref_id (
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

DECLARE @jobName NVARCHAR(100) = N'Databasen Salg - Extract og Archive'
DECLARE @message NVARCHAR(100) = N'Setting up agent job ''' + @jobName + N''''
RAISERROR (@message, 0, 1) WITH NOWAIT

DECLARE	@quit_with_succes INT = 1
DECLARE	@quit_with_failure INT = 2

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
 

DECLARE @trackNumber INT = 
CASE @@servicename 
	WHEN N'SPOR1' THEN 1
	WHEN N'SPOR2' THEN 2
	WHEN N'SPOR3' THEN 3
	WHEN N'SPOR4' THEN 4
	ELSE 1
END 

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
			@description=N'Dette SQL agentjob henter opdateringer om salg ind fra eksterne datakilder.', 
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

DECLARE @stepName nvarchar(100) = N'Master Salg Extract & Archive' 

DELETE @ref
INSERT INTO @ref(id) EXECUTE #ref_id @folder = N'Landingszone', @project = N'Probas'

DECLARE @command nvarchar(500) = CONCAT(
	N'/ISSERVER "\"\SSISDB\Salg\Salg\Master Salg.dtsx\"" /SERVER "\"',
	@@servername,
	N'\""',
	N' /ENVREFERENCE ' + (SELECT id FROM @ref),
	N' /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E')

-- Add step 1: Master Probas Extract & Archive
SET @message = N'Creating job step ''' + @stepName + ''''
RAISERROR (@message, 0, 1) WITH NOWAIT


EXEC msdb.dbo.sp_add_jobstep
		@job_id = @jobId,
		@step_name = @stepName, 
		@cmdexec_success_code = 0, 
		@on_success_action = @quit_with_succes,
		@on_fail_action = @quit_with_failure, 
		@retry_attempts = 0, 
		@retry_interval = 0, 
		@os_run_priority = 0,
		@subsystem = N'SSIS', 
		@command = @command,
		@server = @@servername, 
		@database_name = N'master', 
		@flags = 0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


-- Remove all existing schedules
DECLARE @scheduleId INTEGER
SELECT TOP(1) @scheduleId = schedule_id FROM msdb.dbo.sysjobschedules WHERE job_id = @jobId
WHILE @scheduleId IS NOT NULL
BEGIN
    EXECUTE msdb.dbo.sp_detach_schedule @job_id = @jobId, @schedule_id = @scheduleId, @delete_unused_schedule = 1
    SET @scheduleId = NULL
    SELECT TOP(1) @scheduleId = schedule_id FROM msdb.dbo.sysjobschedules WHERE job_id = @jobId
END

--SIT-miljø er altid spor 1.
DECLARE @schedulename NVARCHAR(50) = 
CASE @trackNumber 
	WHEN 1 THEN 'Daily at 03:15'
	WHEN 2 THEN 'Daily at 03:30'
	WHEN 3 THEN 'Daily at 03:45'
	WHEN 4 THEN 'Daily at 04:00'
END

DECLARE @starttime INT =
CASE @trackNumber 	
	WHEN 1 THEN 31500
	WHEN 2 THEN 33000
	WHEN 3 THEN 34500
	WHEN 4 THEN 40000
END

--For at sikre at de to miljøer: 'AT-PBI-U1' og 'AT-PBI-U2' ikke kører på samme tid indenfor hvert spor.
IF HOST_NAME() = N'AT-PBI-U1' 
SET @starttime = @starttime + 10000

SET @message = 'Creating job schedule ' + @schedulename

IF NOT EXISTS(SELECT * FROM msdb.dbo.sysschedules WHERE name = @schedulename) BEGIN
	RAISERROR (@message, 0, 1) WITH NOWAIT
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule
			@job_id=@jobId,
			@name=@schedulename, 
			@enabled=1, 
			@freq_type=4, --hver dag kl. 3:15 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=0, 
			@active_start_date=20200319, 
			@active_end_date=99991231, 
			@active_start_time = @starttime, 
			@active_end_time=235959

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
ELSE BEGIN
	RAISERROR ('Assigning job schedule', 0, 1) WITH NOWAIT
	EXEC @ReturnCode = msdb.dbo.sp_attach_schedule @job_id=@jobId, @schedule_name=@schedulename
		
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
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
