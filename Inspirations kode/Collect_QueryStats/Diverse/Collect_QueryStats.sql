USE [dba]
GO

--TRUNCATE TABLE [dbo].[QueryStats]
--;

SET NOCOUNT ON
;
DECLARE @i INT = 1
;
WHILE (@i <= 20) 

BEGIN

	INSERT INTO [dbo].[QueryStats]
	SELECT 
		getdate() as TimeSampled,
		datediff(second, t1.start_time, getdate()) as RuntimeSec,
		t1.session_id, 
		t1.blocking_session_id,
		t1.open_transaction_count,
		t1.start_time as request_start_time,
		db_name(t1.database_id) as DatabaseName,
		t1.logical_reads as LogicalReadsPages, 
		t1.logical_reads*8/1024/1024 as LogicalReadsGB,
		t1.cpu_time as CpuMs, 
		t1.total_elapsed_time as TotalElapsedTimeMs, 
		t1.wait_time as WaitTimeMs, 
		t1.wait_type,
		t1.wait_resource,
		SUBSTRING(text, (statement_start_offset/2)+1, 
			((CASE statement_end_offset
			  WHEN -1 THEN DATALENGTH(text)
			 ELSE statement_end_offset
			 END - statement_start_offset)/2) + 1) AS statement_text,
			 text as full_statement_text,
		t3.login_time,
		t3.program_name,
		login_name,
		client_net_address,	
		t3.host_process_id,
		t3.host_name,
		IsolationLevel = case t3.transaction_isolation_level
			when 0 then'Unspecified'
			when 1 then 'ReadUncomitted'
			when 2 then 'ReadCommitted'
			when 3 then 'Repeatable'
			when 4 then 'Serializable'
			when 5 then 'Snapshot'
		end,
		t1.plan_handle,
		query_plan,
		t5.requested_memory_kb/1024 as RequestedMB, 
		t5.granted_memory_kb/1024 as GrantedMB,
		t5.request_time as MemoryGrantRequestTime,
		t5.grant_time as MemoryGrantGrantedTime,
		TempDBInfo.TempDBUsageMB_TempTables,
		TempDBInfo.TempDBUsageMB_SortJoinEtc,
		TLogInfo.LogUsedMB
	FROM 
		sys.dm_exec_requests t1
		outer apply sys.dm_exec_sql_text(sql_handle) t2
		outer apply sys.dm_exec_query_plan(t1.plan_handle)
		inner join sys.dm_exec_sessions t3 on t1.session_id = t3.session_id
		inner join (select distinct session_id, client_net_address from sys.dm_exec_connections) t4 on t1.session_id = t4.session_id
		left outer join sys.dm_exec_query_memory_grants t5 on t1.session_id = t5.session_id
		left outer join (
			select session_id, sum(user_objects_alloc_page_count)*8/1024 as TempDBUsageMB_TempTables, sum(internal_objects_alloc_page_count)*8/1024 as TempDBUsageMB_SortJoinEtc 
			from (
				select session_id,user_objects_alloc_page_count,internal_objects_alloc_page_count from sys.dm_db_task_space_usage
				union all
				select session_id,user_objects_alloc_page_count,internal_objects_alloc_page_count from sys.dm_db_session_space_usage
			) t
			group by session_id
		) as TempDBInfo ON t1.session_id = TempDBInfo.session_id
		LEFT OUTER JOIN (
			SELECT
				t2.[session_id],
				SUM(t1.[database_transaction_log_bytes_used]/1024/1024) AS LogUsedMB
			FROM sys.dm_tran_database_transactions t1
			INNER JOIN sys.dm_tran_session_transactions t2 ON t2.[transaction_id] = t1.[transaction_id]
			GROUP BY t2.[session_id]
		) TLogInfo ON t1.session_id = TLogInfo.session_id
	WHERE t1.session_id > 50 and t1.session_id <> @@spid
	;

	SET @i = @i + 1
	;

	WAITFOR DELAY '00:00:15'
	;

END