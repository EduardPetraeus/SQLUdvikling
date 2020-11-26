USE [EDW_Utility]
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

IF OBJECT_ID('schedule.ufn_VerifySqlJobIsRunning') IS NOT NULL
  DROP FUNCTION [schedule].[ufn_VerifySqlJobIsRunning];
  ELSE PRINT 'Function schedule.ufn_VerifySqlJobIsRunning dont exist';

GO

/************************************************* 
 USE OF INLINE TABLE VALUED FUNCTION 
*************************************************/ 

CREATE FUNCTION [schedule].[ufn_VerifySqlJobIsRunning]
(
@p_JobNAME SYSNAME
) 
RETURNS TABLE
AS 
/************************************************* 
 USE OF INLINE TABLE VALUED FUNCTION 
*************************************************/
RETURN  
(
		-- Finds the last job start
		SELECT TOP 1
			A.job_id
			,A.stop_execution_date
		FROM [msdb].[dbo].[sysjobs_view] AS J

		INNER JOIN [msdb].[dbo].[sysjobactivity] AS A
		ON (J.job_id = A.job_id)

		INNER JOIN (
		-- Only for the last AgentSession
			SELECT
				session_id
				,ROW_NUMBER() OVER (ORDER BY session_id DESC) AS RN
			FROM [msdb].[dbo].[syssessions]
		) AS S 
		ON (A.session_id = S.session_id
		AND S.RN = 1)

		WHERE A.run_Requested_date IS NOT NULL
		AND J.[name] = @p_JobNAME
		ORDER BY A.run_requested_date DESC
)      	
;

GO

---- Input
--DECLARE @JobNAME SYSNAME = N'CloudAPI Load Test'

--IF
---- Checks if the Job is running
--	NOT EXISTS(    
--		SELECT 1
--		FROM (
--			SELECT * 
--			FROM [monitor].[ufn_VerifySqlJobIsRunning] (@JobNAME)
--		) AS A
--		WHERE stop_execution_date IS NULL
--	) 

--BEGIN
--	PRINT('Job will be started immediately')
--	END
--ELSE 
--BEGIN
--	DECLARE @ErrorMessage nvarchar(max) = 'The job "' + @JobNAME + '" is already running'
--	RAISERROR(@ErrorMessage, 16, 1)
--END