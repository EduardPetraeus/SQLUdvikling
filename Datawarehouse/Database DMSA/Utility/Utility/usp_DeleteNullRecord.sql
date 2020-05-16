CREATE PROCEDURE [Utility].[usp_DeleteNullRecord]
    @SchemaName SYSNAME = N'DMSA',
	@TableType SYSNAME = N'BASE TABLE',
    @PrintOnly BIT = 0
AS
BEGIN

		DECLARE @DimensionName NVARCHAR(255)
		DECLARE @SQL NVARCHAR(255)
		DECLARE @PrimaryKey NVARCHAR(255)
		
		
		DECLARE Table_cursor CURSOR FOR 
			SELECT T.TABLE_NAME
			FROM INFORMATION_SCHEMA.TABLES T
			LEFT JOIN (SELECT 
													 col.COLUMN_NAME 
													,col.TABLE_NAME
													,LEFT(col.COLUMN_NAME,4) Prefix
												FROM INFORMATION_SCHEMA.COLUMNS as col
												INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE usage
													ON	col.TABLE_SCHEMA = usage.TABLE_SCHEMA
														AND col.TABLE_NAME = usage.TABLE_NAME
														AND Col.COLUMN_NAME = usage.COLUMN_NAME
												INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS cons
													ON	col.TABLE_SCHEMA=cons.TABLE_SCHEMA
														AND col.TABLE_NAME = cons.TABLE_NAME
														AND usage.CONSTRAINT_NAME = cons.CONSTRAINT_NAME
														AND cons.CONSTRAINT_TYPE = 'PRIMARY KEY'
												WHERE	col.TABLE_SCHEMA = 'DMSA'
														AND col.TABLE_NAME in (	SELECT TABLE_NAME
																			FROM INFORMATION_SCHEMA.TABLES
																			WHERE	TABLE_SCHEMA = 'DMSA'
																					AND TABLE_TYPE = 'BASE TABLE'
																					AND (TABLE_NAME like 'Dim_%' OR TABLE_NAME like '%_DIM')
																			)
														AND (LEFT(col.COLUMN_NAME,4) = 'Ekey')) C
				ON T.TABLE_NAME = C.TABLE_NAME
			WHERE	T.TABLE_SCHEMA = 'DMSA'
					AND TABLE_TYPE = 'BASE TABLE'
					AND T.TABLE_NAME like 'Dim_%'
					AND C.Prefix = 'Ekey' -- Definition of prefix for primary key columns

		
		OPEN Table_cursor  
		FETCH NEXT FROM Table_cursor INTO  @DimensionName
		
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
		
		      SET @PrimaryKey = (	SELECT 
										col.COLUMN_NAME 
									FROM INFORMATION_SCHEMA.COLUMNS as col
									INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE usage
										ON	col.TABLE_SCHEMA = usage.TABLE_SCHEMA
											AND col.TABLE_NAME = usage.TABLE_NAME
											AND Col.COLUMN_NAME = usage.COLUMN_NAME
									INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS cons
										ON	col.TABLE_SCHEMA=cons.TABLE_SCHEMA
											AND col.TABLE_NAME = cons.TABLE_NAME
											AND usage.CONSTRAINT_NAME = cons.CONSTRAINT_NAME
											AND cons.CONSTRAINT_TYPE = 'PRIMARY KEY'
									WHERE	col.TABLE_SCHEMA = 'DMSA'
											AND col.TABLE_NAME = @DimensionName
									)
		
		SET @SQL = 	'DELETE FROM [DMSA].<DimensionName> WHERE <@PrimaryKey> = -1'
				
				SET @SQL = REPLACE(@SQL, N'<@PrimaryKey>', @PrimaryKey);
				SET @SQL = REPLACE(@SQL, N'<DimensionName>', @DimensionName);
		
				EXEC (@SQL)
		
		      FETCH NEXT FROM Table_cursor INTO  @DimensionName
		END 
		
		CLOSE Table_cursor  
		DEALLOCATE Table_cursor 

END
