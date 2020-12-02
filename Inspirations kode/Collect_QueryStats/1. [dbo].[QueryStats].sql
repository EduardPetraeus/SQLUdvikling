USE [Maintenance]
GO

DROP TABLE IF EXISTS [dbo].[QueryStats]
;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[QueryStats](
	[TimeSampled] [datetime] NOT NULL,
	[RuntimeSec] [int] NULL,
	[session_id] [smallint] NOT NULL,
	[blocking_session_id] [smallint] NULL,
	[open_transaction_count] [int] NOT NULL,
	[request_start_time] [datetime] NOT NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[LogicalReadsPages] [bigint] NOT NULL,
	[LogicalReadsGB] [bigint] NULL,
	[CpuMs] [int] NOT NULL,
	[TotalElapsedTimeMs] [int] NOT NULL,
	[WaitTimeMs] [int] NOT NULL,
	[wait_type] [nvarchar](60) NULL,
	[wait_resource] [nvarchar](256) NOT NULL,
	[statement_text] [nvarchar](max) NULL,
	[full_statement_text] [nvarchar](max) NULL,
	[login_time] [datetime] NOT NULL,
	[program_name] [nvarchar](128) NULL,
	[login_name] [nvarchar](128) NOT NULL,
	[client_net_address] [nvarchar](48) NULL,
	[host_process_id] [int] NULL,
	[host_name] [nvarchar](128) NULL,
	[IsolationLevel] [varchar](14) NULL,
	[plan_handle] [varbinary](64) NULL,
	[query_plan] [xml] NULL,
	[RequestedMB] [bigint] NULL,
	[GrantedMB] [bigint] NULL,
	[MemoryGrantRequestTime] [datetime] NULL,
	[MemoryGrantGrantedTime] [datetime] NULL,
	[TempDBUsageMB_TempTables] [bigint] NULL,
	[TempDBUsageMB_SortJoinEtc] [bigint] NULL,
	[LogUsedMB] [bigint] NULL
)
;
GO


