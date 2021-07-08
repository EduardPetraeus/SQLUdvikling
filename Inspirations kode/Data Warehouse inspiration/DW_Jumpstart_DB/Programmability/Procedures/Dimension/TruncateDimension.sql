CREATE PROCEDURE [Dimension].[TruncateDimension]
    @DimensionName SYSNAME,
    @PrintOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @SQL NVARCHAR(MAX) = N'DELETE FROM Dimension.[' + @DimensionName + '];'

	IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('Dimension.[' + @DimensionName + ']'))
		SET @SQL = @SQL + N'DBCC CHECKIDENT ("[Dimension].[' + @DimensionName + ']", RESEED, 0);'

    IF @PrintOnly = 1
        EXEC Utility.PrintLargeString @SQL
    ELSE
        EXECUTE sp_executesql @SQL

    RETURN 0
END
