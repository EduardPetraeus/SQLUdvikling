CREATE TABLE [Utility].[Calendar] (
    [DateKey]                 BIGINT        NOT NULL,
    [Date]                    DATE          NOT NULL,
    [YearKey]                 BIGINT        NOT NULL,
    [YearByWeekKey]           BIGINT        NOT NULL,
    [QuarterKey]              BIGINT        NOT NULL,
    [QuarterByWeekKey]        BIGINT        NOT NULL,
    [MonthKey]                BIGINT        NOT NULL,
    [WeekKey]                 BIGINT        NOT NULL,
    [WeekdayKey]              BIGINT        NOT NULL,
    [DayInYearKey]            BIGINT        NOT NULL,
    [DayInMonthKey]           BIGINT        NOT NULL,
    [IsLastDayInMonth]        BIT           NOT NULL,
    [IsLeapYear]              BIT           NOT NULL,
    [DaysFromPalmSunday]      BIGINT        NOT NULL,
    CONSTRAINT [PK_Calendar2] PRIMARY KEY CLUSTERED ([DateKey] ASC)
);



