CREATE VIEW [Utility].[Calendar_DK]
AS (

  SELECT [DateKey]
    ,[Date]
    ,[YearKey]
    ,CONCAT(N'År ', [YearKey]) AS [Year]
    ,[YearByWeekKey]
    ,CONCAT(N'År ', [YearByWeekKey]) AS [YearByWeek]
    ,[QuarterKey]
    ,CONCAT([QuarterKey], N'. kvartal') AS [Quarter]
    ,[QuarterByWeekKey]
    ,CONCAT([QuarterByWeekKey], N'. kvartal') AS [QuarterByWeek]
    ,[MonthKey]
    ,CASE [MonthKey]
        WHEN 1  THEN N'Januar'
        WHEN 2  THEN N'Februar'
        WHEN 3  THEN N'Marts'
        WHEN 4  THEN N'April'
        WHEN 5  THEN N'Maj'
        WHEN 6  THEN N'Juni'
        WHEN 7  THEN N'Juli'
        WHEN 8  THEN N'August'
        WHEN 9  THEN N'September'
        WHEN 10 THEN N'Oktober'
        WHEN 11 THEN N'November'
        WHEN 12 THEN N'December'
    END [Month]
    ,[WeekKey]
    ,CONCAT(N'Uge ', [WeekKey]) AS [Week]
    ,[WeekdayKey]
    ,CASE [WeekdayKey]
        WHEN 1 THEN N'Mandag'
        WHEN 2 THEN N'Tirsdag'
        WHEN 3 THEN N'Onsdag'
        WHEN 4 THEN N'Torsdag'
        WHEN 5 THEN N'Fredag'
        WHEN 6 THEN N'Lørdag'
        WHEN 7 THEN N'Søndag'
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