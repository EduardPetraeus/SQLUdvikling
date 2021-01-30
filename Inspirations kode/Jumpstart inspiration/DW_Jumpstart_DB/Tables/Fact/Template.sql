/*CREATE TABLE [Fact].[Template]
(
    /* Keys */
    [BusinessKey1] BIGINT NOT NULL,  

    /* References */
    [EKey_Date] BIGINT NOT NULL,

    /* Attributes and measures */
    [Attribute1] NVARCHAR (10) NULL,
    [Measure1] DECIMAL (18, 2) NULL,

    /* Metadata */
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL, -- Reference to the audit framework
    [Meta_UpdateTime] DATETIME NULL,
    [Meta_UpdateJob] BIGINT NULL, -- Reference to the audit framework    

    /* Constraints */
    CONSTRAINT [PK_Template] PRIMARY KEY CLUSTERED ([BusinessKey1]),
    CONSTRAINT [FK_Template_Date] FOREIGN KEY ([EKey_Date]) REFERENCES [Dimension].[Date]([EKey_Date]),
)
GO

*/