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

IF OBJECT_ID('schedule.ufn_VerifySqlJobIsEnable') IS NOT NULL
  DROP FUNCTION [schedule].[ufn_VerifySqlJobIsEnable];
  ELSE PRINT 'Function schedule.ufn_VerifySqlJobIsEnable dont exist';

GO

/************************************************* 
 USE OF SCALAR VALUED FUNCTION 
*************************************************/ 

CREATE FUNCTION [schedule].[ufn_VerifySqlJobIsEnable]
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
		@v_IsEnable BIT
	   ,@v_JobNAME SYSNAME
	;
	SET @v_IsEnable = 0
	SET @v_JobNAME = @p_JobNAME
	;

	SELECT @v_IsEnable = 1 
	FROM [msdb].[dbo].[sysjobs_view] AS J
	WHERE J.[name] = @v_JobNAME
	AND J.[enabled] = 1
	;
	RETURN @v_IsEnable
END
;

GO

---- Input
--DECLARE @JobNAME SYSNAME = N'DBA.CollectDBStats1'
--SELECT [schedule].[ufn_VerifySqlJobIsEnable](@JobNAME)
