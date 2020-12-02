USE [msdb]
GO

DECLARE 
	@ReturnCode INT
	,@v_Database NVARCHAR(100)
	,@v_OwnerLoginName NVARCHAR(50)	
	,@v_JobName NVARCHAR(200) 
;

DECLARE 
	@v_JobId BINARY(16)
	,@v_JobIdText NVARCHAR(50)
;

SET @v_Database = N'Maintenance'
SET @v_OwnerLoginName = N'sa'
SET @v_JobName = 'DBA.CollectQueryStats'
;

SET @v_JobIdText = (SELECT TOP 1 job_id FROM [dbo].[sysjobs_view] WHERE [name] = @v_JobName)
;

-- Delete Job if exists
IF @v_JobIdText IS NOT NULL
	EXEC msdb.dbo.sp_delete_job @job_id=@v_JobIdText, @delete_unused_schedule=1
;

BEGIN TRANSACTION

SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@v_JobName, 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job collects samples of running sql statements', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@v_OwnerLoginName, @job_id = @v_JobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@v_JobId, @step_name=@v_JobName, 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON
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
			when 0 then''Unspecified''
			when 1 then ''ReadUncomitted''
			when 2 then ''ReadCommitted''
			when 3 then ''Repeatable''
			when 4 then ''Serializable''
			when 5 then ''Snapshot''
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

	WAITFOR DELAY ''00:00:15''
	;

END', 
		@database_name=@v_Database, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @v_JobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@v_JobId, @name=N'CollectQueryStats30Min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20200506, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'fa7622a5-b7d1-4a9e-b294-20d169655edc'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@v_JobId, @name=N'CollectQueryStatsDaily', 
		@enabled=0, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20200604, 
		@active_end_date=99991231, 
		@active_start_time=90000, 
		@active_end_time=235959, 
		@schedule_uid=N'2dd6b032-1ae5-40a5-af8c-7d22ee1226ce'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @v_JobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


