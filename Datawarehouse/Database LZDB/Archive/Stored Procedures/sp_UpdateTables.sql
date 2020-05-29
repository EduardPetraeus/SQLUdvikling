CREATE PROCEDURE [Archive].[sp_UpdateTables]

	 @DestinationTableName nvarchar(1000) = 'Lokation'
   
   AS
 

declare @cmd nvarchar(max) = '
UPDATE lsl
SET lsl.LastSuccesfullJobId = x.maxUpdateJob
FROM [RZDB].[Meta].[LastSuccesfullLoad] lsl
INNER JOIN (
    SELECT Source_TableName, MAX(Source_UpdateJob) maxUpdateJob 
    FROM [Load].<<DestinationTableName>>
    GROUP BY Source_TableName
    ) x 
    ON lsl.SourceTableName = x.Source_TableName 
    AND lsl.TableName = ''<<DestinationTableName>>''
';
set @cmd = replace(@cmd, '<<DestinationTableName>>', @DestinationTableName);
print @cmd;
exec sp_executesql @cmd;

 
declare @cmd2 nvarchar(max) = '
 MERGE INTO [RZDB].[Meta].[LastSuccesfullLoad] as lsl
 USING (
    SELECT Source_TableName, MAX(Source_UpdateJob) maxUpdateJob 
    FROM [Load].<<DestinationTableName>>
    GROUP BY Source_TableName
    ) as src 
    ON (lsl.SourceTableName = src.Source_TableName 
    AND lsl.TableName = ''<<DestinationTableName>>'')
WHEN MATCHED THEN
    UPDATE SET lsl.LastSuccesfullJobId = src.maxUpdateJob
WHEN NOT MATCHED BY TARGET THEN
    INSERT (TableName, SourceTableName, LastSuccesfullJobId) 
    VALUES (''<<DestinationTableName>>'', src.Source_TableName, src.maxUpdateJob)
'
;
set @cmd2 = replace(@cmd2, '<<DestinationTableName>>', @DestinationTableName);
print @cmd2;
exec sp_executesql @cmd2;