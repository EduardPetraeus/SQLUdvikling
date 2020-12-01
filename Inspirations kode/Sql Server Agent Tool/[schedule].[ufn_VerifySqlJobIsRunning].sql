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

IF OBJECT_ID('schedule.ufn_VerifySqlJobIsRunning') IS NOT NULL
  DROP FUNCTION [schedule].[ufn_VerifySqlJobIsRunning];
  ELSE PRINT 'Function schedule.ufn_VerifySqlJobIsRunning dont exist';

GO

/************************************************* 
 USE OF SCALAR VALUED FUNCTION 
*************************************************/ 

CREATE FUNCTION [schedule].[ufn_VerifySqlJobIsRunning]
(
@p_JobNAME SYSNAME
) 
RETURNS BIT
AS 
/************************************************* 
 USE OF SCALAR VALUED FUNCTION 
*************************************************/
BEGIN
	DECLARE 
		@v_JobIsRunning BIT
	   ,@v_JobNAME SYSNAME
	;
	SET @v_JobIsRunning = 0
	SET @v_JobNAME = @p_JobNAME
	;
	-- Finds the last job start
	SELECT @v_JobIsRunning = 1 
	FROM [msdb].[dbo].[sysjobs_view] AS J
	INNER JOIN [msdb].[dbo].[sysjobactivity] AS A
	ON (J.job_id = A.job_id)
	WHERE A.run_Requested_date IS NOT NULL
	AND A.stop_execution_date IS NULL
	AND J.[name] = @v_JobNAME
	ORDER BY A.run_requested_date DESC
    ;

	RETURN @v_JobIsRunning

END
;
GO

---- Input
--DECLARE @JobNAME SYSNAME = 'DBA.CollectIOStats'
--SELECT [schedule].[ufn_VerifySqlJobIsRunning](@JobNAME)
