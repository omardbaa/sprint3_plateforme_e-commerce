-- Check if the table GeneratedDate exists
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'GeneratedDate')
BEGIN
    -- Create the GeneratedDate table if it doesn't exist
    CREATE TABLE GeneratedDate (
        Date DATE,
        Year INT,
        Month INT,
        Day INT
    );

    -- Generate all days for 2021, 2022, and 2023
    DECLARE @StartDate DATE = '2021-01-01';
    DECLARE @EndDate DATE = '2023-12-31';

    WHILE @StartDate <= @EndDate
    BEGIN
        INSERT INTO GeneratedDate (Date, Year, Month, Day)
        SELECT
            @StartDate AS DateString,
            YEAR(@StartDate) AS Year,
            MONTH(@StartDate) AS Month,
            DAY(@StartDate) AS Day;

        SET @StartDate = DATEADD(DAY, 1, @StartDate);
    END;
END
ELSE
BEGIN
    -- Table already exists, no need to create it
    PRINT 'Table "GeneratedDate" already exists.';
END;

select * from GeneratedDate


