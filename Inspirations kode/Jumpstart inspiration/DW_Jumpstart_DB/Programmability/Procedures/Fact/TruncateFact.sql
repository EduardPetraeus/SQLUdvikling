CREATE PROCEDURE [Fact].[TruncateFact]
    @FactName NVARCHAR (50),
    @PrintOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @NewLine NVARCHAR(2) = CHAR(13)

    DECLARE @SQL NVARCHAR(MAX) = ''
    SET @SQL = 'TRUNCATE TABLE Fact.[' + @FactName + ']'

    IF @PrintOnly = 1
    BEGIN
        EXEC Utility.PrintLargeString @SQL
    END
    ELSE
    BEGIN
        EXECUTE sp_executesql @SQL
    END

    RETURN 0
END
