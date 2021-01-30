CREATE PROCEDURE [Utility].[GenerateCalendar]
    @Date DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SET NOCOUNT ON

    -- Set first day of week to Monday
    SET DATEFIRST 1

    DECLARE	@DateKey BIGINT
    DECLARE	@YearKey  BIGINT
    DECLARE	@YearByWeekKey BIGINT
    DECLARE	@QuarterKey BIGINT
    DECLARE	@QuarterByWeekKey BIGINT
    DECLARE @MonthKey BIGINT    
    DECLARE	@WeekKey BIGINT  
    DECLARE	@WeekdayKey BIGINT
    DECLARE	@DayInYearKey BIGINT
    DECLARE	@DayInMonthKey BIGINT
    DECLARE @IsLastDayInMonth BIT
    DECLARE	@IsLeapYear BIT
    DECLARE	@DaysFromPalmSynday BIGINT

    DECLARE @PalmSunday DATETIME
    DECLARE @ThursdayInWeek DATETIME
    DECLARE @LastYear INT = NULL

    -- Build the calendar
    WHILE (@Date <= @EndDate)
    BEGIN
	
        /* -------------------------------------- *\
        If year changed recalculate palm Sunday
        http://www.assa.org.au/edm.html#Computer
        \* -------------------------------------- */
        IF @LastYear IS NULL OR @LastYear <> DATEPART(YEAR, @Date)
        BEGIN
	        -- Intermediate results
	        DECLARE @FirstDig bigint
	        DECLARE @Remain19 bigint
	        DECLARE @temp bigint 
	   
	        -- Table A to E results
	        DECLARE @tA bigint
	        DECLARE @tB bigint
	        DECLARE @tC bigint
	        DECLARE @tD bigint
	        DECLARE @tE bigint        
	   
	        DECLARE @d bigint
	        DECLARE @m bigint   
	   
            -- Calculate Paschal Full Moon (PFM) date
	        SET @FirstDig = DATEPART(YEAR, @Date) / 100 -- First 2 digits of year
	        SET @Remain19 = DATEPART(YEAR, @Date) % 19  -- Remainder of year / 19

	        SET @temp = (@FirstDig - 15) / 2 + 202 - 11 * @Remain19    
	    
	        SET @temp = CASE @FirstDig 
				WHEN 21 THEN @temp - 1
				WHEN 24 THEN @temp - 1
				WHEN 25 THEN @temp - 1
				WHEN 27 THEN @temp - 1
				WHEN 28 THEN @temp - 1
				WHEN 29 THEN @temp - 1
				WHEN 30 THEN @temp - 1
				WHEN 31 THEN @temp - 1
				WHEN 32 THEN @temp - 1
				WHEN 34 THEN @temp - 1
				WHEN 35 THEN @temp - 1
				WHEN 38 THEN @temp - 1
				WHEN 33 THEN @temp - 2
				WHEN 36 THEN @temp - 2
				WHEN 37 THEN @temp - 2
				WHEN 39 THEN @temp - 2
				WHEN 40 THEN @temp - 2
				ELSE @temp
			END    
	   
	        SET @temp = @temp % 30

	        SET @tA = @temp + 21
		    IF (@temp = 29)
                SET @tA = @tA - 1
		    IF (@temp = 28 And @Remain19 > 10)
                SET @tA = @tA - 1
	   
	        -- Find the next Sunday
	        SET @tB = (@tA - 19) % 7
	    
	        SET @tC = (40 - @FirstDig) % 4
		    IF (@tC = 3)  
			    SET @tC = @tC + 1
		    IF (@tC > 1)  
			    SET @tC = @tC + 1
	       
	        SET @temp = DATEPART(YEAR, @Date) % 100
	        SET @tD = (@temp + @temp / 4) % 7
	    
	        SET @tE = ((20 - @tB - @tC - @tD) % 7) + 1
	        SET @d = @tA + @tE

	        -- Return the date
	        IF (@d > 31) 
	        BEGIN
		      SET @d = @d - 31
		      SET @m = 4
	        END
	        ELSE
	        BEGIN
		      SET @m = 3
	        END

	        SET @PalmSunday = CONVERT(DATETIME, CONVERT(NVARCHAR, DATEPART(YEAR, @Date)) +
                                                RIGHT('0' + CONVERT(NVARCHAR, @m), 2) + 
                                                RIGHT('0' + CONVERT(NVARCHAR, @d), 2), 112) - 7
        END
        /* -------------------------------------- *\
        DONE!
        \* -------------------------------------- */

		SET  @ThursdayInWeek = @Date - DATEPART(DW, @Date) + 1 + 3	

		-- Date key
	    SET @DateKey = DATEPART (YEAR, @Date) * 10000 +
	                   DATEPART (MONTH, @Date) * 100 +
	                   DATEPART (DAY, @Date)
		
		-- Get vital date informations
		SET @YearKey = DATEPART(YEAR, @Date)
		
		SET @YearByWeekKey = DATEPART(YEAR, @ThursdayInWeek)

		SET @QuarterKey = DATEPART(QUARTER, @Date) 
		
		SET @QuarterByWeekKey = DATEPART(QUARTER, @ThursdayInWeek) 
		
		SET @MonthKey = DATEPART(MONTH, @Date)
		
        SET @WeekKey = DATEPART(ISO_WEEK, @Date)

		SET @WeekdayKey = DATEPART(DW, @Date)

		SET @DayInYearKey = DATEPART(DY, @Date)
		
		SET @DayInMonthKey = DATEPART(DAY, @Date)

        SET @DaysFromPalmSynday = DATEDIFF(DAY, @PalmSunday, @Date)
		
        -- Last day in month
        IF DATEPART(DAY, DATEADD(DAY, 1, @Date)) = 1
            SET @IsLastDayInMonth = 1
        ELSE
            SET @IsLastDayInMonth = 0

		-- Leap year	
        IF ((@YearKey % 4 = 0) AND (@YearKey % 100 != 0 OR @YearKey % 400 = 0))
			SET @IsLeapYear = 1
		ELSE 
			SET @IsLeapYear = 0

		-- Insert values in table
		INSERT [Utility].[Calendar] (		
			[DateKey],
			[Date],
			[YearKey],
			[YearByWeekKey],
			[QuarterKey],  
			[QuarterByWeekKey],   
			[MonthKey],   
			[WeekKey],
			[WeekdayKey],
			[DayInYearKey],
			[DayInMonthKey],
            [IsLastDayInMonth],
			[IsLeapYear],
            [DaysFromPalmSunday]
		 )
		VALUES 
		(
			 @DateKey
			,@Date
			,@YearKey
			,@YearByWeekKey
			,@QuarterKey
			,@QuarterByWeekKey
			,@MonthKey
			,@WeekKey
			,@WeekdayKey
			,@DayInYearKey
			,@DayInMonthKey
            ,@IsLastDayInMonth
			,@IsLeapYear
            ,@DaysFromPalmSynday
		)

		-- Increment the date one day
		SELECT @Date = DATEADD(DAY, 1, @Date)

	END
	
END
