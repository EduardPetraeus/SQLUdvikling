CREATE VIEW [Utility].[Calendar_UK]
AS (

  SELECT [DateKey]
    ,[Date]
    ,[YearKey]
    ,CAST(CONCAT(N'Year ', [YearKey]) AS NVARCHAR(9)) AS [Year]
    ,[YearByWeekKey]
    ,CAST(CONCAT(N'Year ', [YearByWeekKey]) AS NVARCHAR(9)) AS [YearByWeek]
    ,[QuarterKey]
    ,CAST(CONCAT(N'Quarter ', [QuarterKey]) AS NVARCHAR(10)) AS [Quarter]
    ,[QuarterByWeekKey]
    ,CAST(CONCAT(N'Quarter ', [QuarterByWeekKey]) AS NVARCHAR(10)) AS [QuarterByWeek]
    ,[MonthKey]
    ,CASE [MonthKey]
        WHEN 1  THEN N'January'
        WHEN 2  THEN N'February'
        WHEN 3  THEN N'March'
        WHEN 4  THEN N'April'
        WHEN 5  THEN N'May'
        WHEN 6  THEN N'June'
        WHEN 7  THEN N'July'
        WHEN 8  THEN N'August'
        WHEN 9  THEN N'September'
        WHEN 10 THEN N'October'
        WHEN 11 THEN N'November'
        WHEN 12 THEN N'December'
    END [Month]
    ,[WeekKey]
    ,CAST(CONCAT(N'Week ', [WeekKey]) AS NVARCHAR(7)) AS [Week]
    ,[WeekdayKey]
    ,CASE [WeekdayKey]
        WHEN 1 THEN N'Monday'
        WHEN 2 THEN N'Tuesday'
        WHEN 3 THEN N'Wednesday'
        WHEN 4 THEN N'Thursday'
        WHEN 5 THEN N'Friday'
        WHEN 6 THEN N'Saturday'
        WHEN 7 THEN N'Sunday'
    END [Weekday]	
    ,[DayInYearKey]
    ,[DayInMonthKey]
    ,[IsLastDayInMonth] AS [LastDayInMonthKey]
    ,[IsLeapYear] AS [LeapYearKey]
    ,CASE WHEN [WeekdayKey] IN (6, 7) THEN 1 ELSE 0 END AS [IsWeekend]
    ,CASE
        WHEN [MonthKey] = 12 and [DayInMonthKey] = 24 THEN 1
        WHEN [MonthKey] = 12 and [DayInMonthKey] = 25 THEN 1
        WHEN [MonthKey] = 12 and [DayInMonthKey] = 26 THEN 1
        WHEN [MonthKey] = 12 and [DayInMonthKey] = 31 THEN 1
        WHEN [MonthKey] = 1 and [DayInMonthKey] = 1 THEN 1
        WHEN [MonthKey] = 5 and [DayInMonthKey] = 1 THEN 1
        WHEN [MonthKey] = 6 and [DayInMonthKey] = 5 THEN 1
        -- Påske
        WHEN [DaysFromPalmSunday] = 4 THEN 1
        WHEN [DaysFromPalmSunday] = 5 THEN 1
        WHEN [DaysFromPalmSunday] = 7 THEN 1
        WHEN [DaysFromPalmSunday] = 8 THEN 1
        -- Bededag
        WHEN [DaysFromPalmSunday] = 33 THEN 1
        -- Kristihimmelfartsdag
        WHEN [DaysFromPalmSunday] = 46 THEN 1
        -- Pinse
        WHEN [DaysFromPalmSunday] = 56 THEN 1
        WHEN [DaysFromPalmSunday] = 57 THEN 1
        ELSE 0
    END AS IsHoliday_DK
    ,[DaysFromPalmSunday]
  FROM [Utility].[Calendar]

)