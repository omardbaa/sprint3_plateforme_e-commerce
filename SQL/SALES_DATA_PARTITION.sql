-- Use the DataMartSales database
USE DataMartSales;

-- Create partition function for Sales
CREATE PARTITION FUNCTION SalesDatePartitionFunction (DATE)
AS RANGE LEFT FOR VALUES ('2021-09-28', '2022-01-01', '2023-01-01');

-- Create filegroups
ALTER DATABASE DataMartSales ADD FILEGROUP [FG_sales_Archive];
ALTER DATABASE DataMartSales ADD FILEGROUP [FG_sales_2021];
ALTER DATABASE DataMartSales ADD FILEGROUP [FG_sales_2022];
ALTER DATABASE DataMartSales ADD FILEGROUP [FG_sales_2023];

-- Associate filegroups with files (adjust file paths and sizes as needed)
ALTER DATABASE DataMartSales ADD FILE
(
    NAME = N'sales_Archive',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\sales_Archive.ndf',
    SIZE = 2048KB
) TO FILEGROUP [FG_sales_Archive];

ALTER DATABASE DataMartSales ADD FILE
(
    NAME = N'sales_2021',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\sales_2021.ndf',
    SIZE = 2048KB
) TO FILEGROUP [FG_sales_2021];

ALTER DATABASE DataMartSales ADD FILE
(
    NAME = N'sales_2022',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\sales_2022.ndf',
    SIZE = 2048KB
) TO FILEGROUP [FG_sales_2022];

ALTER DATABASE DataMartSales ADD FILE
(
    NAME = N'sales_2023',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\sales_2023.ndf',
    SIZE = 2048KB
) TO FILEGROUP [FG_sales_2023];

-- Create partition scheme
CREATE PARTITION SCHEME salesPartitionScheme
AS PARTITION SalesDatePartitionFunction
TO ([Primary], [FG_sales_2021], [FG_sales_2022], [FG_sales_2023]);

-- Drop existing view if it exists
IF OBJECT_ID('salesFactView', 'V') IS NOT NULL
    DROP VIEW salesFactView;

-- Create a view to extract the required data
CREATE VIEW salesFactView
AS
SELECT
    sf.SaleID,
    sf.DateID,
    sf.ProductID,
    sf.CustomerID,
    sf.QuantitySold,
    sf.TotalAmount,
    sf.DiscountAmount,
    sf.NetAmount,
    sf.ShipperID,
    sf.ProductPrice,
    dd.Date AS SalesDate
FROM
    SalesFact sf
JOIN
    DimDate dd ON sf.DateID = dd.DateID;
DROP TABLE Sales_Fact
-- Create the partitioned table with foreign key constraints
CREATE TABLE Sales_Fact
(
    SaleID INT,
    DateID INT,
    ProductID INT,
    CustomerID INT,
    QuantitySold INT,
    TotalAmount DECIMAL(18, 2),
    DiscountAmount DECIMAL(18, 2),
    NetAmount DECIMAL(18, 2),
    ShipperID INT,
    ProductPrice DECIMAL(18, 2),
    SalesDate DATE,
    PRIMARY KEY (SaleID, SalesDate),
    CONSTRAINT FK_DateID FOREIGN KEY (DateID) REFERENCES DimDate(DateID) ON DELETE CASCADE,
    CONSTRAINT FK_ProductID FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID) ON DELETE CASCADE,
    CONSTRAINT FK_CustomerID FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT FK_ShipperID FOREIGN KEY (ShipperID) REFERENCES DimShipper(ShipperID) ON DELETE CASCADE
)
ON salesPartitionScheme (SalesDate);

-- Insert data into the partitioned table
INSERT INTO Sales_Fact (SaleID, DateID, ProductID, CustomerID, QuantitySold, TotalAmount, DiscountAmount, NetAmount, ShipperID, ProductPrice, SalesDate)
SELECT SaleID, DateID, ProductID, CustomerID, QuantitySold, TotalAmount, DiscountAmount, NetAmount, ShipperID, ProductPrice, SalesDate
FROM salesFactView;

-- Display partition information
SELECT 
    p.partition_number AS partition_number,
    f.name AS file_group, 
    p.rows AS row_count
FROM sys.partitions p
JOIN sys.destination_data_spaces dds ON p.partition_number = dds.destination_id
JOIN sys.filegroups f ON dds.data_space_id = f.data_space_id
WHERE OBJECT_NAME(OBJECT_ID) = 'Sales_Fact'
ORDER BY partition_number;
SELECT * FROM sys.filegroups;
