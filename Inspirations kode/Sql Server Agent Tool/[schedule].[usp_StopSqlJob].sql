USE [Maintenance]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF SCHEMA_ID('schedule') IS NULL
EXECUTE sys.sp_executesql N'CREATE SCHEMA [schedule];';
ELSE PRINT 'Schema [schedule] already exist'
;
GO

IF OBJECT_ID('schedule.usp_StopSqlJob', 'P') IS NOT NULL
  DROP PROCEDURE [schedule].[usp_StopSqlJob];
  ELSE PRINT 'PROCEDURE schedule.usp_StopSqlJob dont exist';

GO

CREATE PROCEDURE [schedule].[usp_StopSqlJob] (
 @p_JobName SYSNAME
,@p_RunStatus INT OUTPUT
)
AS

-- =============================================
-- Author:		Mike Ritter, NC
-- Create date: 2018-03-25
-- Description:	Stop a SQL Agent Job
-- @result:	0 -> Success
--			1 -> Error
-- Use:
-- DECLARE @v_return INT;
-- EXEC [schedule].[usp_StopSqlJob] @p_JobName='Load Test', @p_RunStatus=@v_return OUTPUT
-- =============================================

	SET NOCOUNT ON

	DECLARE 
		 @v_JobId UNIQUEIDENTIFIER
		,@v_JobName SYSNAME
		,@v_Retval INT
		,@v_JobRunTime INT
		,@v_InternalDelayinSecond NVARCHAR(8)
	    ,@v_RunStatus INT 	
		,@v_JobExist BIT
		,@v_JobIsRunning BIT
		,@v_JobIsEnable BIT
	;
	
	SET @v_InternalDelayinSecond = '00:00:02'
	SET @v_JobRunTime = 0
	SET @v_RunStatus  = 0 -- default
	SET @v_JobName = @p_JobName
	;

	-- Verify that this job exists
	SET @v_JobExist = (SELECT [schedule].[ufn_VerifySqlJobExist](@v_JobName))
	;
	IF @v_JobExist = 0
	BEGIN
		SET @v_RunStatus = 1 -- Job Not Exists\Unknown
	    SET @p_RunStatus = @v_RunStatus
		;
		RAISERROR('Invalid job name ''%s''', 16, 245, @v_JobName);
		RETURN 1
	END;

	--Get the job_id
	SET @v_JobId = (SELECT TOP 1 job_id FROM [msdb].[dbo].[sysjobs] WHERE [name] = @v_JobName)
	;

	-- Check to make sure job is running
	SET @v_JobIsRunning = (SELECT [schedule].[ufn_VerifySqlJobIsRunning](@v_JobName))
	;
	-- Check to make sure job is enable
	SET @v_JobIsEnable = (SELECT [schedule].[ufn_VerifySqlJobIsEnable](@v_JobName))
	;

	-- Stop the Job when it's running
	IF @v_JobIsRunning = 1
	BEGIN
		-- Check if Job is enable
		IF @v_JobIsEnable = 1
		BEGIN
			-- Enable the Job
			EXEC[msdb].[dbo].[sp_update_job] @job_name = @v_JobName, @enabled = 0
			;
			RAISERROR('Job ''%s'' is disabled', 0, 1, @v_JobName) WITH NOWAIT
			;
		END -- Job is disabled

		EXEC @v_Retval = [msdb].[dbo].[sp_stop_job] @job_id = @v_JobId;

		-- Waiting to allow SQL Agent to post first status of job in sysjobhistory
		WAITFOR DELAY @v_InternalDelayinSecond
		;

		IF @v_Retval <> 0		
		BEGIN		
			SET @v_RunStatus = 1	
			SET @p_RunStatus = @v_RunStatus		
			;		
			RAISERROR('Job ''%s'' could not be stopped', 16, 245, @v_JobName)		
			;		
			RETURN @v_RunStatus;		
		END;		

		-- Get the final stats		
		SELECT @v_JobRunTime = CASE WHEN stop_execution_date IS NULL THEN DATEDIFF(SECOND, start_execution_date, GETDATE()) ELSE 0 END 		
		FROM ( 		
			SELECT ja.start_execution_date		
				  ,ja.stop_execution_date		
			FROM [msdb].[dbo].[sysjobactivity] ja		
			WHERE ja.session_id = (		
				SELECT MAX(session_id) 		
				FROM [msdb].[dbo].[sysjobactivity] ja1 		
				WHERE ja1.job_id = ja.job_id 		
				AND	ja1.run_requested_date IS NOT NULL		
			)		
			AND	job_id = @v_JobId		

		) JobActivity		
		;		

	END
	ELSE
		RAISERROR('Job ''%s'' is not running', 0, 1, @v_JobName) WITH NOWAIT
	;

	RAISERROR('Job completed in ''%d'' seconds.', 0, 1, @v_JobRunTime) WITH NOWAIT;
	SET @p_RunStatus = @v_RunStatus
	;

	RETURN	@v_RunStatus
	; 

GO

--DECLARE @v_return INT;
----EXEC [schedule].[usp_StopSqlJob] @p_JobName='CloudAPI Load Test', @p_RunStatus=@v_return OUTPUT
--EXEC [schedule].[usp_StopSqlJob] @p_JobName='DBA.CollectIOStats', @p_RunStatus=@v_return OUTPUT
--PRINT @v_return