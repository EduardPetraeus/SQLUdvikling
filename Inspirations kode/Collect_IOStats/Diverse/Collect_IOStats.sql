USE [dba]
GO

DECLARE 
   @v_initial BIT
;

SET @v_initial = 0
;

IF (@v_initial = 0)
BEGIN
	TRUNCATE TABLE [dbo].[IOStats]
	;
END

SET NOCOUNT ON
;
DECLARE @i INT = 0
;

WHILE (@i <= 20) 
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

	WAITFOR DELAY '00:01:00'
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

END