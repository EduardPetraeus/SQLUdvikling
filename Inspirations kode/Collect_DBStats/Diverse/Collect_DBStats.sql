USE [dba]
GO

--Truncate table [dbo].[dbStats]
--;

SET NOCOUNT ON
;
DECLARE
	@v_Sql NVARCHAR(1000)
;
DECLARE 
	@i INT = 1
;

SET @v_Sql = 'Use [?];
Insert into [dba].[temp].[dbStats] (
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
	IIF([type_desc] = ''ROWS'', ''DATA'', [type_desc]),
	CAST(SUM([size]/(128.0*1024.0)) As Decimal(10,2)), 
	CAST(SUM(Fileproperty([name], ''SpaceUsed'')/(128.0*1024.0)) As Decimal(10,2)),
	NULL,
	NULL,
	NULL
From sys.database_files 
GROUP BY [type_desc]
;'
;

WHILE (@i <= 5) 
BEGIN

	TRUNCATE TABLE [temp].[dbStats]
	;
	EXEC sp_MSforeachdb @v_Sql
	;
	UPDATE D
	SET
		[FreeGB] = [SizeGB] - [UsedGB],
		[PcntUsed] = ([UsedGB]/(IIF([SizeGB]=0,1,[SizeGB])))*100,
		[PcntFree] = (([SizeGB]-[UsedGB])/(IIF([SizeGB]=0,1,[SizeGB])))*100

	FROM [temp].[dbStats] D
	;

	INSERT INTO [dbo].[dbStats]
	SELECT * FROM [temp].[dbStats]
	;

	WAITFOR DELAY '00:01:00'
	;

	SET @i = @i + 1
	;

END