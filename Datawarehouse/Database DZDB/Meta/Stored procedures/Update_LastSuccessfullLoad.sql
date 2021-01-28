CREATE PROCEDURE [Meta].[Update_LastSuccessfullLoad]
	@p_DestinationTableName NVARCHAR(50),
	@p_Schema               NVARCHAR(20),
	@p_Database             NVARCHAR(30)
		
AS
	DECLARE @v_SourceTablename NVARCHAR(100) = '[' + @p_Database + ']' + '.' + '[' + @p_Schema + ']' + '.' + '[' + @p_DestinationTableName + ']'
	
DECLARE @SQL NVARCHAR(max)

SET @SQL = '
	 MERGE INTO [DZDB].[Meta].[LastSuccessfullLoad] as lsl
 USING (
    SELECT Source_TableName, MAX(Source_UpdateJob) AS maxUpdateJob 
    FROM <v_SourceTablename>
    GROUP BY Source_TableName
    ) as src 
    ON (lsl.SourceTableName = src.Source_TableName 
    AND lsl.DestinationTableName = ''<p_DestinationTableName>'')
WHEN MATCHED THEN
    UPDATE SET lsl.LastSuccessfullJobId = src.maxUpdateJob
WHEN NOT MATCHED BY TARGET THEN
    INSERT (DestinationTableName, SourceTableName, LastSuccessfullJobId) 
    VALUES (''<p_DestinationTableName>'', src.Source_TableName, src.maxUpdateJob);
'


SET @SQL = REPLACE(@SQL,'<v_SourceTablename>', @v_SourceTablename);
SET @SQL = REPLACE(@SQL,'<p_DestinationTableName>', @p_DestinationTableName);

--PRINT @SQL

	EXECUTE sp_executesql @SQL
