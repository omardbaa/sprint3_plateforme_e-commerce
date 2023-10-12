USE plateforme_e-commerce_data_warehouse;

-- Create a test class
EXEC tSQLt.NewTestClass 'DW_Tests';

-- Create a test procedure for testing valid date format
ALTER PROCEDURE DW_Tests.[test ValidDateFormat]
AS
BEGIN
    -- Act: Query the table for dates with an incorrect format
    DECLARE @incorrectFormatDates INT;
    SELECT @incorrectFormatDates = COUNT(*)
    FROM [plateforme_e-commerce_data_warehouse].[dbo].[DimDate]
    WHERE TRY_CAST([date] AS DATETIME) IS NULL
    OR FORMAT([date], 'yyyy-MM-dd') != [date];

    -- Assert: Verify that there are no dates with an incorrect format
    EXEC tSQLt.AssertEquals 0, @incorrectFormatDates;
END;

-- Create a test procedure for testing valid product price
ALTER PROCEDURE DW_Tests.[test PriceValidation]
AS
BEGIN
    -- Act: Query the table for discrepancies in ProductPrice calculation
    DECLARE @incorrectCalculations INT;
    SELECT @incorrectCalculations = COUNT(*)
    FROM [plateforme_e-commerce_data_warehouse].[dbo].[FactSales]
    WHERE ROUND([TotalAmount] / [QuantitySold], 0) != [ProductPrice];

    -- Assert: Verify that there are no discrepancies in ProductPrice calculation
    EXEC tSQLt.AssertEquals 0, @incorrectCalculations;
END;

-- Create a test procedure for testing valid product name and category
ALTER PROCEDURE DW_Tests.[test NameAndCategoryValidation]
AS
BEGIN
    -- Act: Query the table for invalid product names and categories
    DECLARE @invalidProductNames INT;
    DECLARE @invalidProductCategories INT;
    
    SELECT @invalidProductNames = COUNT(*)
    FROM [plateforme_e-commerce_data_warehouse].[dbo].[DimProduct]
    WHERE [ProductName] = 'NonExistentProduct';
    
    SELECT @invalidProductCategories = COUNT(*)
    FROM [plateforme_e-commerce_data_warehouse].[dbo].[DimProduct]
    WHERE [ProductCategory] = 'InvalidCategory';
    
    -- Assert: Verify that there are no occurrences of invalid product names or categories
    EXEC tSQLt.AssertEquals 0, @invalidProductNames;
    EXEC tSQLt.AssertEquals 0, @invalidProductCategories;
END;



EXEC tSQLt.Run 'DW_Tests.[test ValidDateFormat]'

EXEC tSQLt.Run 'DW_Tests.[test NameAndCategoryValidation]'

EXEC tSQLt.Run 'DW_Tests.[test NameAndCategoryValidation]'
