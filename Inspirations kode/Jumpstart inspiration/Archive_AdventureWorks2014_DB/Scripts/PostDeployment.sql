/*
Post-Deployment Script Template                            
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.        
 Use SQLCMD syntax to include a file in the post-deployment script.            
 Example:      :r .\myfile.sql                                
 Use SQLCMD syntax to reference a variable in the post-deployment script.        
 Example:      :setvar TableName MyTable                            
               SELECT * FROM [$(TableName)]                    
--------------------------------------------------------------------------------------
*/


/* Insert fixed values */
RAISERROR ('Inserting fixed values into [Utility].[FixedValues]', 0, 1) WITH NOWAIT

MERGE [Utility].[FixedValues] t
USING (VALUES ('DateNull', '18000101'),
              ('DateBOU', '18000101'),
              ('DateEOU', '99991231'),
              ('UnknownText', 'Unknown')) s ([Key], [Value])
ON t.[Key] = s.[Key]

WHEN MATCHED
    THEN UPDATE
    SET [Value] = s.[Value]

WHEN NOT MATCHED BY TARGET
    THEN INSERT ([Key], [Value]) VALUES (s.[Key], s.[Value])
;

/* Load SSIS codes */
:r Data\SSISCodes.sql