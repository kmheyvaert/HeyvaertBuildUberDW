--Uber Revenue Data Mart Developed and Written by Annie Vellon and Kelsey Heyvaert 
--------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases
    WHERE name=N'UberDW1')
    CREATE DATABASE UberDW1

GO
USE UberDW1

--------------------------------------------------------------------------
--Delete Existing Tables: 

IF EXISTS(
    SELECT *
    FROM sys.tables
    WHERE name=N'FactRevenue'
    )
DROP TABLE FactRevenue;

IF EXISTS(
	SELECT *
	FROM sys.tables
	WHERE name=N'DimTrip'
	)
DROP TABLE DimTrip;

IF EXISTS(
    SELECT *
    FROM sys.tables
    WHERE name=N'DimLocation'
    )
DROP TABLE DimLocation;

IF EXISTS(
    SELECT *
    FROM sys.tables
    WHERE name=N'DimService'
    )
DROP TABLE DimService;

IF EXISTS(
    SELECT *
    FROM sys.tables
    WHERE name=N'DimDate'
    )
DROP TABLE DimDate;

IF EXISTS(
    SELECT *
    FROM sys.tables
    WHERE name=N'DimDriver'
    )
DROP TABLE DimDriver;

IF EXISTS(
	SELECT *
	FROM sys.tables
	WHERE name=N'DimWeather'
	)
DROP TABLE DimWeather;
--------------------------------------------------------------------------

--Create Tables

CREATE TABLE DimDriver
    (DriverSK							INT NOT NULL IDENTITY (1,1) CONSTRAINT pk_DimDriver PRIMARY KEY,
     DriverAK							NVARCHAR(255) NOT NULL,
     Rating								INT,
     YearsExperience                    INT,
     CommissionRate						INT NOT NULL
    );


CREATE TABLE DimDate
	(Date_SK							INT NOT NULL IDENTITY (1,1) CONSTRAINT pk_DimDate PRIMARY KEY,
	Date DATETIME,
	DayOfMonth VARCHAR(2), -- Field will hold day number of Month
	DayName VARCHAR(9), -- Contains name of the day, Sunday, Monday 
	DayOfWeek CHAR(1),-- First Day Sunday=1 and Saturday=7
	DayOfWeekInMonth VARCHAR(2), -- 1st Monday or 2nd Monday in Month
	Month VARCHAR(2), -- Number of the Month 1 to 12{}
	MonthName VARCHAR(9),-- January, February etc
	Quarter CHAR(1),
	Year CHAR(4),-- Year value of Date stored in Row
	Holiday VARCHAR(50),--Name of Holiday in US
	);

CREATE TABLE DimService 
	(ServiceSK							INT NOT NULL IDENTITY (1,1) CONSTRAINT pk_DimService PRIMARY KEY,
	ServiceAk							NVARCHAR(255),
	Size								NVARCHAR(1) NOT NULL,
	LuxaryLevel							NVARCHAR(10) NOT NULL
	);

CREATE TABLE DimLocation
	(LocationSK							INT NOT NULL IDENTITY (1,1) CONSTRAINT pk_DimLocation PRIMARY KEY,
	LocationAK							NVARCHAR(255) NOT NULL,
	[State]								NVARCHAR(2) NOT NULL,
	City								NVARCHAR(30) NOT NULL,
	ZipCode								NVARCHAR(5) NOT NULL
	);

CREATE TABLE DimTrip					
	(TripSK								INT NOT NULL IDENTITY (1,1) CONSTRAINT pk_DimTrip PRIMARY KEY,
	TripAK								NVARCHAR(255) NOT NULL,
	StartTime							DateTime NOT NULL,
	EndTime								DateTime NOT NULL
	); 

CREATE TABLE DimWeather 
	(WeatherSK							INT NOT NULL IDENTITY (1,1) CONSTRAINT pk_DimWeather PRIMARY KEY, 
	[Date]								DATETIME,
	Season								NVARCHAR(25),
	Conditions							NVARCHAR(35),
	PredictedAvgTemp					INT, 
	ActualAvgTemp						INT,
	PrecipitationProbability			DECIMAL
	); 

CREATE TABLE FactRevenue
	(DriverSK											INT NOT NULL,
	Date_SK												INT NOT NULL, 
	LocationSK											INT NOT NULL,
	ServiceSK											INT NOT NULL,
	TripSK												INT NOT NULL,
	WeatherSK											INT NOT NULL,
	BaseFee												Decimal,
	SurgeRate											Decimal,
	Discount											Decimal,
	TotalCharge											Decimal,
	TripDuration										DateTime,
	CONSTRAINT pk_FactRevenue							PRIMARY KEY (DriverSK, Date_SK, LocationSK, ServiceSK,TripSK,WeatherSK),
	CONSTRAINT fk_DimDriver								FOREIGN KEY (DriverSK) 
		REFERENCES DimDriver(DriverSK),
	CONSTRAINT fk_DimDate								FOREIGN KEY(Date_SK)
		REFERENCES DimDate(Date_SK), 
	CONSTRAINT fk_DimLocation							FOREIGN KEY(LocationSK) 
		REFERENCES DimLocation(LocationSK), 
	CONSTRAINT fk_DimTrip								FOREIGN KEY(TripSK)
		REFERENCES DimTrip(TripSK),
	CONSTRAINT fk_DimWeather 							FOREIGN KEY(WeatherSK)
		REFERENCES DimWeather(WeatherSK)	
	);

--------------------------------------------------------------------------

--List table names and row counts for confirmation

GO
SET NOCOUNT ON
SELECT 'DimLocation'"Table",	COUNT(*) "Rows"	FROM DimLocation            UNION
SELECT 'DimService',			COUNT(*)		FROM DimService				UNION
SELECT 'DimDate',				COUNT(*)		FROM DimDate				UNION
SELECT 'DimDriver',				COUNT(*)		FROM DimDriver				UNION
SELECT 'DimTrip',				COUNT(*)		FROM DimTrip				UNION
SELECT 'FactRevenue',			COUNT(*)		FROM FactRevenue


ORDER BY 1;
SET NOCOUNT OFF
GO

--DimLocation

SELECT
LocationAK=UberOLTP1.dbo.Trip.TripID,
[State]=UberOLTP1.dbo.Trip.TripState,
City=UberOLTP1.dbo.Trip.TripCity,
Zipcode=UberOLTP1.dbo.Trip.PickupZipCode

FROM UberOLTP1.dbo.Trip

GO

--DimService 

SELECT
ServiceAK=UberOLTP1.dbo.Car.LicensePlate,
Size=UberOLTP1.dbo.Car.NumberOfSeats,
LuxaryLevel=UberOLTP1.dbo.Car.LuxuryLevel

FROM UberOLTP1.dbo.Car

GO

--DimDate
/*****************************************************************************************/
--DimDate
/*****************************************************************************************/

USE UberDW1


GO 
-- Specify start date and end date here
-- Value of start date must be less than your end date 

DECLARE @StartDate DATETIME = '01/01/2010' -- Starting value of date range
DECLARE @EndDate DATETIME = GETDATE() -- End Value of date range

-- Temporary variables to hold the values during processing of each date of year
DECLARE
	@DayOfWeekInMonth INT,
	@DayOfWeekInYear INT,
	@DayOfQuarter INT,
	@WeekOfMonth INT,
	@CurrentYear INT,
	@CurrentMonth INT,
	@CurrentQuarter INT

-- Table data type to store the day of week count for the month and year
DECLARE @DayOfWeek TABLE (DOW INT, MonthCount INT, QuarterCount INT, YearCount INT)

INSERT INTO @DayOfWeek VALUES (1, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (2, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (3, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (4, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (5, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (6, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (7, 0, 0, 0)

-- Extract and assign various parts of values from current date to variable

DECLARE @CurrentDate AS DATETIME = @StartDate
SET @CurrentMonth = DATEPART(MM, @CurrentDate)
SET @CurrentYear = DATEPART(YY, @CurrentDate)
SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)

-- Proceed only if start date(current date ) is less than end date you specified above

WHILE @CurrentDate < @EndDate
BEGIN
 
-- Begin day of week logic

	/*Check for change in month of the current date if month changed then change variable value*/
	IF @CurrentMonth <> DATEPART(MM, @CurrentDate) 
	BEGIN
		UPDATE @DayOfWeek
		SET MonthCount = 0
		SET @CurrentMonth = DATEPART(MM, @CurrentDate)
	END

	/* Check for change in quarter of the current date if quarter changed then change variable value*/

	IF @CurrentQuarter <> DATEPART(QQ, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET QuarterCount = 0
		SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)
	END
       
	/* Check for Change in Year of the Current date if Year changed then change variable value*/
	
	IF @CurrentYear <> DATEPART(YY, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET YearCount = 0
		SET @CurrentYear = DATEPART(YY, @CurrentDate)
	END
	
-- Set values in table data type created above from variables 

	UPDATE @DayOfWeek
	SET 
		MonthCount = MonthCount + 1,
		QuarterCount = QuarterCount + 1,
		YearCount = YearCount + 1
	WHERE DOW = DATEPART(DW, @CurrentDate)

	SELECT
		@DayOfWeekInMonth = MonthCount,
		@DayOfQuarter = QuarterCount,
		@DayOfWeekInYear = YearCount
	FROM @DayOfWeek
	WHERE DOW = DATEPART(DW, @CurrentDate)
	
-- End day of week logic

	/* Populate your dimension table with values*/
	
	INSERT INTO DimDate
	SELECT
		--CONVERT (char(8),@CurrentDate,112) AS Date_SK,
		@CurrentDate AS [Date],
		DATEPART(DD, @CurrentDate) AS DayOfMonth,
		DATENAME(DW, @CurrentDate) AS DayName,
		DATEPART(DW, @CurrentDate) AS DayOfWeek,
		@DayOfWeekInMonth AS DayOfWeekInMonth,
		DATEPART(MM,@CurrentDate) AS Month,
		DATENAME(MM, @CurrentDate) AS MonthName,
		DATEPART(QQ, @CurrentDate) AS Quarter,
		DATEPART(YEAR, @CurrentDate) AS Year,
		NULL AS Holiday

	SET @CurrentDate = DATEADD(DD, 1, @CurrentDate)
END

--Update values of holiday as per USA Govt. Declaration for National Holiday

	-- THANKSGIVING - Fourth THURSDAY in November
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Thanksgiving Day'
	WHERE
		[Month] = 11 
		AND [DayOfWeek] = 'Thursday' 
		AND DayOfWeekInMonth = 4

	-- CHRISTMAS
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Christmas Day'
		
	WHERE [Month] = 12 AND [DayOfMonth]  = 25

	-- 4th of July
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Independance Day'
	WHERE [Month] = 7 AND [DayOfMonth] = 4

	-- New Years Day
	UPDATE [dbo].[DimDate]
		SET Holiday = 'New Year''s Day'
	WHERE [Month] = 1 AND [DayOfMonth] = 1

	-- Memorial Day - Last Monday in May
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Memorial Day'
	FROM [dbo].[DimDate]
	WHERE Date_SK IN 
		(
		SELECT
			MAX(Date_SK)
		FROM [dbo].[DimDate]
		WHERE
			[Month] = 'May'
			AND [DayOfWeek]  = 'Monday'
		GROUP BY
			[Year],
			[Month]
		)

	-- Labor Day - First Monday in September
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Labor Day'
	FROM [dbo].[DimDate]
	WHERE Date_SK IN 
		(
		SELECT
			MIN(Date_SK)
		FROM [dbo].[DimDate]
		WHERE
			[Month] = 'September'
			AND [DayOfWeek] = 'Monday'
		GROUP BY
			[Year],
			[Month]
		)

	-- Valentine's Day
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Valentine''s Day'
	WHERE
		[Month] = 2 
		AND [DayOfMonth] = 14

	-- Saint Patrick's Day
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Saint Patrick''s Day'
	WHERE
		[Month] = 3
		AND [DayOfMonth] = 17

	-- Martin Luthor King Day - Third Monday in January starting in 1983
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Martin Luthor King Jr Day'
	WHERE
		[Month] = 1
		AND [DayOfWeek]  = 'Monday'
		AND [Year] >= 1983
		AND DayOfWeekInMonth = 3

	-- President's Day - Third Monday in February
	UPDATE [dbo].[DimDate]
		SET Holiday = 'President''s Day'
	WHERE
		[Month] = 2
		AND [DayOfWeek] = 'Monday'
		AND DayOfWeekInMonth = 3

	-- Mother's Day - Second Sunday of May
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Mother''s Day'
	WHERE
		[Month] = 5
		AND [DayOfWeek] = 'Sunday'
		AND DayOfWeekInMonth = 2

	-- Father's Day - Third Sunday of June
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Father''s Day'
	WHERE
		[Month] = 6
		AND [DayOfWeek] = 'Sunday'
		AND DayOfWeekInMonth = 3

	-- Halloween 10/31*/
	UPDATE [dbo].[DimDate]
		SET Holiday = 'Halloween'
	WHERE
		[Month] = 10
		AND [DayOfMonth] = 31

	-- Election Day - The first Tuesday after the first Monday in November
	BEGIN
	DECLARE @Holidays TABLE (ID INT IDENTITY(1,1), 
	DateID int, Week TINYINT, YEAR CHAR(4), DAY CHAR(2))

		INSERT INTO @Holidays(DateID, [Year],[Day])
		SELECT
			Date_SK,
			[Year],
			[DayOfMonth] 
		FROM [dbo].[DimDate]
		WHERE
			[Month] = 11
			AND [DayOfWeek] = 'Monday'
		ORDER BY
			YEAR,
			DayOfMonth 

		DECLARE @CNTR INT, @POS INT, @STARTYEAR INT, @ENDYEAR INT, @MINDAY INT

		SELECT
			@CURRENTYEAR = MIN([Year]),
			@STARTYEAR = MIN([Year]),
			@ENDYEAR = MAX([Year])
		FROM @Holidays

		WHILE @CURRENTYEAR <= @ENDYEAR
		BEGIN
			SELECT @CNTR = COUNT([Year])
			FROM @Holidays
			WHERE [Year] = @CURRENTYEAR

			SET @POS = 1

			WHILE @POS <= @CNTR
			BEGIN
				SELECT @MINDAY = MIN(DAY)
				FROM @Holidays
				WHERE
					[Year] = @CURRENTYEAR
					AND [Week] IS NULL
					  
				UPDATE @Holidays
					SET [Week] = @POS
				WHERE
					[Year] = @CURRENTYEAR
					AND [Day] = @MINDAY

				SELECT @POS = @POS + 1
			END

			SELECT @CURRENTYEAR = @CURRENTYEAR + 1
		END

		UPDATE [dbo].[DimDate]
			SET Holiday  = 'Election Day'				
		FROM [dbo].[DimDate] DT
			JOIN @Holidays HL ON (HL.DateID + 1) = DT.Date_SK
		WHERE
			[Week] = 1
	END

	--Code Used to Fill Dim Tables 

	SELECT * FROM [dbo].[DimDate]
/*****************************************************************************************/

--DimDriver

SELECT 
DriverAK=UberOLTP1.dbo.Driver.DriverLicenseNumer,
Rating=UberOLTP1.dbo.Driver.Rating,
YearsExperience=DATEDIFF(mm,UberOLTP1.dbo.Driver.StartDate,GETDATE()),
CommissionRate=UberOLTP1.dbo.Driver.CommissionRate

FROM UberOLTP1.dbo.Driver

GO 

--DimTrip

SELECT
TripAK=UberOLTP1.dbo.Trip.TripID,
StartTime=UberOLTP1.dbo.Trip.StartTime,
EndTime=UberOLTP1.dbo.Trip.EndTime

FROM UberOLTP1.dbo.Trip

GO

--Code Used to Fill Fact Table 
---------------------------------------------------------------
--FactSales

SELECT 
UberDW1.dbo.DimDriver.DriverSK,
UberDW1.dbo.DimDate.Date_SK,
UberDW1.dbo.DimLocation.LocationSK,
UberDW1.dbo.DimService.ServiceSK,
UberDW1.dbo.DimTrip.TripSK,
UberDW1.dbo.DimWeather.WeatherSK,
BaseFee=UberOLTP1.dbo.Payment.BaseFare,
SurgeRate=UberOLTP1.dbo.Payment.SurgeRate,
Discount=UberOLTP1.dbo.Payment.Discount,
TotalCharge=UberOLTP1.dbo.Payment.BaseFare,
TripDuration=CONVERT(INT, (DATEDIFF(mi,UberOLTP1.dbo.Trip.StartTime,UberOLTP1.dbo.Trip.EndTime)))

FROM UberDW1.dbo.DimDate 

INNER JOIN UberOLTP1.dbo.Trip
	ON UberDW1.dbo.DimDate.[Date]=UberOLTP1.dbo.Trip.TripDate
	
INNER JOIN UberOLTP1.dbo.Driver 
	ON UberOLTP1.dbo.Trip.DriverLicenseNumer=UberOLTP1.dbo.Driver.DriverLicenseNumer
	
INNER JOIN UberOLTP1.dbo.Car
	ON UberOLTP1.dbo.Car.DriverLicenseNumer=UberOLTP1.dbo.Driver.DriverLicenseNumer

INNER JOIN UberOLTP1.dbo.Payment
	ON UberOLTP1.dbo.Payment.PaymentID=UberOLTP1.dbo.Trip.PaymentID
	
INNER JOIN UberDW1.dbo.DimDriver
	ON UberDW1.dbo.DimDriver.DriverAK=UberOLTP1.dbo.Driver.DriverLicenseNumer
	
INNER JOIN UberDW1.dbo.DimLocation
	ON UberDW1.dbo.DimLocation.LocationAK=UberOLTP1.dbo.Trip.TripID

INNER JOIN UberDW1.dbo.DimTrip	
	ON UberDW1.dbo.DimTrip.TripAK=UberOLTP1.dbo.Trip.TripID

INNER JOIN UberDW1.dbo.DimService
	ON UberDW1.dbo.DimService.ServiceAk=UberOLTP1.dbo.Car.LicensePlate
	
INNER JOIN UberDW1.dbo.DimWeather 
	ON UberDW1.dbo.DimWeather.[Date]=UberOLTP1.dbo.Trip.TripDate