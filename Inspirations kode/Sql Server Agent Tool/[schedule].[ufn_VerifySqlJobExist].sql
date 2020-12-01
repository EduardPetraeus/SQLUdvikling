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

IF OBJECT_ID('schedule.ufn_VerifySqlJobExist') IS NOT NULL
  DROP FUNCTION [schedule].[ufn_VerifySqlJobExist];
  ELSE PRINT 'Function schedule.ufn_VerifySqlJobExist dont exist';

GO

/************************************************* 
 USE OF SCALAR VALUED FUNCTION 
*************************************************/ 

CREATE FUNCTION [schedule].[ufn_VerifySqlJobExist]
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
		 @v_Exist BIT
		,@v_JobNAME SYSNAME
	;
	SET @v_Exist = 0
	SET @v_JobNAME = @p_JobNAME
	;
	SELECT @v_Exist = 1 
	FROM [msdb].[dbo].[sysjobs_view] AS J
	WHERE J.[name] = @v_JobNAME
	;
	RETURN @v_Exist
END
;

GO

---- Input
--DECLARE @JobNAME SYSNAME = N'DBA.CollectDBStats1'
--SELECT [schedule].[ufn_VerifySqlJobExist](@JobNAME)
