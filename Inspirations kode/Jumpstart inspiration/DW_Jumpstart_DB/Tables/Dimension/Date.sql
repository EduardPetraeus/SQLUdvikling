CREATE TABLE [Dimension].[Date]
(
    /* Keys */
    [EKey_Date] BIGINT NOT NULL,

    /* Details */
    [Date] DATE, -- 05-04-2015
    [YearKey] INT, -- 2015
    [Year] NVARCHAR(9), -- Year 2015
    [QuarterKey] INT, -- 2
    [Quarter] NVARCHAR(10), -- 2 quarter
    [MonthKey] INT, -- 4
    [Month] NVARCHAR(9), -- April
    [WeekKey] INT, -- 13
    [Week] NVARCHAR(7), -- Week 14
    [WeekdayKey] INT, -- 7
    [Weekday] NVARCHAR(9), -- Sunday
    [DayOfYear] INT, -- 95
    [DayOfMonth] INT, -- 5
    [IsWorkday] BIT, -- 0
    [IsPublicHoliday] BIT, -- 1
    [IsDayWithIce] BIT, -- 0

    /* Metadata */
    [Meta_CreateTime] DATETIME NOT NULL,
    [Meta_CreateJob] BIGINT NOT NULL,

    /* Constraints */
    CONSTRAINT [PK_Date] PRIMARY KEY CLUSTERED ([EKey_Date] ASC),
)
GO
