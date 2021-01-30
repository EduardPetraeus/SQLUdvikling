CREATE PROCEDURE [Dimension].[InsertNullRecord]
    @JobId BIGINT,
    @TableName SYSNAME,
    @SchemaName SYSNAME = N'Dimension',
    @PrintOnly BIT = 0
AS
BEGIN

    SET NOCOUNT ON

    DECLARE @SQL NVARCHAR(MAX) = ''

    -----------------------------------------------------------
    --   Define what Unknown text should be	
    -----------------------------------------------------------

    DECLARE @UnknownText NVARCHAR(50) = (SELECT Value FROM Utility.FixedValues WHERE [Key] = N'UnknownText')
    DECLARE @UnknownDate NVARCHAR(50) = (SELECT Value FROM Utility.FixedValues WHERE [Key] = N'DateNull')
    DECLARE @DateBOU     NVARCHAR(50) = (SELECT Value FROM Utility.FixedValues WHERE [Key] = N'DateBOU')
    DECLARE @DateEOU     NVARCHAR(50) = (SELECT Value FROM Utility.FixedValues WHERE [Key] = N'DateEOU')

	DECLARE @KeyName	SYSNAME = CASE 
									WHEN RIGHT(@TableName, 3) IN (N'_T1', N'_T2') THEN N'EKey_' + LEFT(@TableName, LEN(@TableName) - 3)
									ELSE N'EKey_' + @TableName
								  END

    -----------------------------------------------------------
    --   Verify Existance of Unknown Record
    -----------------------------------------------------------

    SET @SQL = 'SELECT @Exists = 1 FROM ' + @SchemaName + '.' + @TableName + ' WHERE ' + @KeyName + ' = -1'

    DECLARE @Exists BIT
    EXECUTE sp_executesql @SQL, N'@Exists INT OUT', @Exists OUT

    IF @Exists = 1 RETURN 0

    -----------------------------------------------------------
    --   Create Unknown Record
    -----------------------------------------------------------

    DECLARE @ColumnName NVARCHAR(100)
    DECLARE @IsNullable NVARCHAR(10)
    DECLARE @DataType NVARCHAR(50)
    DECLARE @MaxLength INT

    DECLARE @ColumnsList NVARCHAR(MAX) = ''
    DECLARE @ValuesList NVARCHAR(MAX) = ''

    DECLARE ColumnCursor CURSOR FOR 
    SELECT COLUMN_NAME, IS_NULLABLE, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = @TableName

	OPEN ColumnCursor
    FETCH NEXT FROM ColumnCursor INTO @ColumnName, @IsNullable, @DataType, @MaxLength
	WHILE @@fetch_status = 0
    BEGIN

        IF @ColumnName = 'Meta_ValidFrom'
        BEGIN
            SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
            SET @ValuesList = @ValuesList + ', ''' + @DateBOU + ''''
        END

        ELSE IF @ColumnName = 'Meta_ValidTo'
        BEGIN
            SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
            SET @ValuesList = @ValuesList + ', ''' + @DateEOU + ''''
        END
        
        ELSE IF @ColumnName = 'Meta_CreateTime'
        BEGIN
            SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
            SET @ValuesList = @ValuesList + ', GETDATE()'
        END

        ELSE IF @ColumnName = 'Meta_CreateJob'
        BEGIN
            SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
            SET @ValuesList = @ValuesList + ', ' + CAST(@JobId AS NVARCHAR(10))
        END

        ELSE IF @ColumnName IN ('Meta_IsDeleted', 'Meta_IsCurrent', 'Meta_IsInferred')
        BEGIN
            SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
            SET @ValuesList = @ValuesList + ', ' + IIF(@ColumnName = 'Meta_IsDeleted', '0', '1')
        END

        ELSE IF @ColumnName = 'Meta_Hash'
        BEGIN
            SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
            SET @ValuesList = @ValuesList + ', '''''
        END

        ELSE IF @ColumnName  IN (@KeyName, STUFF(@KeyName, 1, 1, N'H'))
        BEGIN
            SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
            SET @ValuesList = @ValuesList + ', -1'
        END

        ELSE IF @ColumnName NOT LIKE 'Meta_%'
        BEGIN
            SET @ColumnsList = @ColumnsList + ', ' + @ColumnName
            SET @ValuesList = @ValuesList + ', ' +
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

				WHEN 'bit' THEN '0'
				WHEN 'tinyint' THEN '0'
				WHEN 'smallint' THEN '0'
				WHEN 'int' THEN '0'
				WHEN 'bigint' THEN '0'

                WHEN 'numeric' THEN '0'
                WHEN 'decimal' THEN '0'
                WHEN 'float' THEN '0'
                WHEN 'real' THEN '0'

				ELSE 'NULL' -- will probably fail 
			END
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

	SET @SQL = 'INSERT ' + @SchemaName +'.' + @TableName + ' (' + @ColumnsList + ') VALUES (' + @ValuesList + ')' + CHAR(10); 
	
    IF EXISTS (SELECT 1 FROM sys.columns WHERE [object_id] = OBJECT_ID(@SchemaName + '.' + @TableName) AND [is_identity] = 1)
    BEGIN
        SET @SQL = 'SET IDENTITY_INSERT ' + @SchemaName + '.' + @TableName + ' ON' + CHAR(10) +
                   @SQL +
                   'SET IDENTITY_INSERT ' + @SchemaName + '.' + @TableName + ' OFF' + CHAR(10);  
    END

	IF @PrintOnly = 0
	    EXECUTE sp_executesql @SQL
    ELSE
        EXECUTE Utility.PrintLargeString @SQL

END

