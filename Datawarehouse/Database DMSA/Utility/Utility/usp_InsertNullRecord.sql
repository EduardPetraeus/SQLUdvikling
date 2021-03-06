CREATE PROCEDURE [Utility].[usp_InsertNullRecord]
    @JobId		BIGINT  = '-1', 
    @SchemaName SYSNAME = N'DMSA',
	@TableType	SYSNAME = N'BASE TABLE',
    @PrintOnly	BIT		= 0
AS
BEGIN

    SET NOCOUNT ON

    DECLARE @SQL NVARCHAR(MAX) = ''

    -----------------------------------------------------------
    --   Define what Unknown text should be       
    -----------------------------------------------------------

    DECLARE @UnknownText		NVARCHAR(50) = 'Ukendt'	--(SELECT Value FROM Utility.FixedValues WHERE [Key] = N'UnknownText')
    DECLARE @UnknownSource		NVARCHAR(50) = 'Ukendt'	--(SELECT Value FROM Utility.FixedValues WHERE [Key] = N'UnknownRecordSource')
    DECLARE @UnknownDate		NVARCHAR(50) = '9999-12-31'	--(SELECT Value FROM Utility.FixedValues WHERE [Key] = N'DateNull')
    DECLARE @DateBOU            NVARCHAR(50) = '9999-12-31'	--(SELECT Value FROM Utility.FixedValues WHERE [Key] = N'DateBOU')
    DECLARE @DateEOU            NVARCHAR(50) = '9999-12-31'	--(SELECT Value FROM Utility.FixedValues WHERE [Key] = N'DateEOU')

    DECLARE @TableName SYSNAME;          
            
            
    -----------------------------------------------------------
    --   Declare cursor to iterate of over dim tables
    -----------------------------------------------------------    
            
    DECLARE TableCursor CURSOR FOR 
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
					

    OPEN TableCursor
		FETCH NEXT FROM TableCursor INTO @TableName
				WHILE @@fetch_status = 0
					BEGIN

                    DECLARE @KeyName SYSNAME =	CASE 
											         WHEN RIGHT(@TableName, 3) IN (N'_T1') THEN N'EKey_' + REPLACE(LEFT(@TableName, LEN(@TableName) - 3), 'Dim_', '')
											         WHEN RIGHT(@TableName, 3) IN (N'_T2') THEN N'HKey_' + REPLACE(LEFT(@TableName, LEN(@TableName) - 3), 'Dim_', '')
													 ELSE N'EKey_' + REPLACE(@TableName, 'Dim_', '')
												END
        
            
                         -----------------------------------------------------------
                         --   Verify Existance of Unknown Record
                         -----------------------------------------------------------

                         SET @SQL = 'SELECT @Exists = 1 FROM ' + @SchemaName + '.' + @TableName + ' WHERE ' + @KeyName + ' = -1'
                         
                         DECLARE @Exists BIT = 0
                         EXECUTE sp_executesql @SQL, N'@Exists INT OUT', @Exists OUT

                         IF @Exists = 1 BEGIN                              
                                     PRINT N'Unknown record already present in ' + @SchemaName + '.' + @TableName + '. Skipping';
                                     FETCH NEXT FROM TableCursor INTO @TableName;
					CONTINUE;
        END

                         -----------------------------------------------------------
                         --   Create Unknown Record
                         -----------------------------------------------------------

                         DECLARE @ColumnName NVARCHAR(100)
                         DECLARE @IsNullable NVARCHAR(10)
                         DECLARE @DataType NVARCHAR(50)
                         DECLARE @MaxLength INT
                         DECLARE @NULL INT = NULL

                         DECLARE @ColumnsList NVARCHAR(MAX) = ''
                         DECLARE @ValuesList NVARCHAR(MAX) = ''

                         DECLARE ColumnCursor CURSOR FOR 
                         SELECT CONCAT('[', COLUMN_NAME, ']') AS COLUMN_NAME, IS_NULLABLE, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
                         FROM INFORMATION_SCHEMA.COLUMNS
                         WHERE TABLE_SCHEMA = @SchemaName
                                     AND TABLE_NAME = @TableName

                         OPEN ColumnCursor
                         FETCH NEXT FROM ColumnCursor INTO @ColumnName, @IsNullable, @DataType, @MaxLength
                         WHILE @@fetch_status = 0
                         BEGIN

                                     IF @ColumnName = '[Meta_ValidFrom]'
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', ', '''', @DateBOU, '''')
                                     END

                                     ELSE IF @ColumnName = '[Meta_ValidTo]'
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', ', '''', @DateEOU, '''')
                                     END
        
                                     ELSE IF @ColumnName = '[Meta_CreateTime]'
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', ', '''', @DateEOU, '''')
                                     END

                                     ELSE IF @ColumnName = '[Meta_CreateJob]'
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', ', CAST(@JobId AS NVARCHAR(10)))
                                     END

                                     ELSE IF @ColumnName IN ( '[Meta_UpdateJob]','[Meta_DeleteJob]','[Meta_DeleteTime]','[Meta_UpdateTime]')
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', NULL')
                                     END


                                     ELSE IF @ColumnName IN ('[Meta_IsDeleted]', '[Meta_IsCurrent]', '[Meta_IsInferred]')
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', ', IIF(@ColumnName = '[Meta_IsDeleted]', '0', '1'))
                                     END

                                     ELSE IF @ColumnName = '[Meta_SysETLID]'
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', -1')
                                     END

                                     ELSE IF @ColumnName = '[Meta_RecordSource]'
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', ', '''', @UnknownSource, '''')
                                     END

                                     ELSE IF @ColumnName = '[Meta_Checksum]'
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', CONVERT(BINARY(32), '''')')
                                     END

                                     -- 0 is an actual business key
                                     ELSE IF @ColumnName = '[RevenueSplitType]'
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', -1')
                                     END

                                     ELSE IF  CHARINDEX('EKey_', @ColumnName, 1) > 0 OR CHARINDEX('HKey_', @ColumnName, 1) > 0
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', -1')
                                     END                                  

                                     ELSE IF @ColumnName NOT LIKE '[Meta_%'
                                     BEGIN
                                                  SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
                                                  SET @ValuesList = CONCAT(@ValuesList, ', ',
                                                  CASE @DataType
                                                              WHEN 'date' THEN '''' + @UnknownDate + ''''
                                                              WHEN 'time' THEN '''00:00:00'''
                                                              WHEN 'datetime' THEN '''' + @UnknownDate + ''''
                                                              WHEN 'datetime2' THEN '''' + @UnknownDate + ''''
                                                              WHEN 'smalldatetime' THEN '''' + @UnknownDate + ''''

                                                              WHEN 'char' THEN '''' + IIF(@MaxLength >= LEN(@UnknownText), @UnknownText, '') + ''''
                                                              WHEN 'varchar' THEN '''' + IIF(@MaxLength >= LEN(@UnknownText), @UnknownText, '') + ''''
                                                              WHEN 'nchar' THEN '''' + IIF(@MaxLength >= LEN(@UnknownText), @UnknownText, '') + ''''
                                                              WHEN 'nvarchar' THEN '''' + IIF(@MaxLength >= LEN(@UnknownText), @UnknownText, '') + ''''

                                                              WHEN 'bit' THEN '-1'
                                                              WHEN 'tinyint' THEN '-1'
                                                              WHEN 'smallint' THEN '-1'
                                                              WHEN 'int' THEN '-1'
                                                              WHEN 'bigint' THEN '-1'

                                                              WHEN 'numeric' THEN '-1'
                                                              WHEN 'decimal' THEN '-1'
                                                              WHEN 'float' THEN '-1'
                                                              WHEN 'real' THEN '-1'
                                                              WHEN 'uniqueidentifier' THEN 'NEWID()'

                                                              ELSE NULL
                                                  END)
                                     END

                                     FETCH NEXT FROM ColumnCursor INTO @ColumnName, @IsNullable, @DataType, @MaxLength

                         END

                         CLOSE ColumnCursor
                         DEALLOCATE ColumnCursor

                         -----------------------------------------------------------
                         --  Execute the SQL statement
                         -----------------------------------------------------------
                         SET @ColumnsList = SUBSTRING(@ColumnsList, 3, LEN(@ColumnsList))
                         SET @ValuesList = SUBSTRING(@ValuesList, 3, LEN(@ValuesList))

                         PRINT N'Columns list: ' + @ColumnsList
                         PRINT N'Values list: ' + @ValuesList

                         SET @SQL = 'INSERT ' + @SchemaName +'.' + @TableName + ' (' + @ColumnsList + ') VALUES (' + @ValuesList + ')' + CHAR(10); 
                         PRINT @SQL
                         
                         IF EXISTS (SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID(@SchemaName + '.' + @TableName) AND [is_identity] = 1)
                         BEGIN
                                     SET @SQL = 'SET IDENTITY_INSERT ' + @SchemaName + '.' + @TableName + ' ON' + CHAR(10) 
												+ @SQL 
												+ 'SET IDENTITY_INSERT ' + @SchemaName + '.' + @TableName + ' OFF' + CHAR(10);  
                         END
                         
                         IF @PrintOnly = 0
                                     EXECUTE sp_executesql @SQL
                         ELSE
                                     EXECUTE Utility.usp_PrintLargeString @SQL                                     

                         FETCH NEXT FROM TableCursor INTO @TableName

            END
            
            CLOSE TableCursor
            DEALLOCATE TableCursor

END
