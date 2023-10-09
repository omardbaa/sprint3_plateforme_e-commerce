USE DataMartInventory;

-- Create partition function for Inventory
CREATE PARTITION FUNCTION InventoryDatePartitionFunction (DATE)
AS RANGE LEFT FOR VALUES ('2021-09-28', '2022-01-01', '2023-01-01');

-- Create filegroups
ALTER DATABASE DataMartInventory ADD FILEGROUP [FG_inventory_Archive];
ALTER DATABASE DataMartInventory ADD FILEGROUP [FG_inventory_2021];
ALTER DATABASE DataMartInventory ADD FILEGROUP [FG_inventory_2022];
ALTER DATABASE DataMartInventory ADD FILEGROUP [FG_inventory_2023];

-- Associate filegroups with files
ALTER DATABASE DataMartInventory ADD FILE
(
    NAME = N'inventory_Archive',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\inventory_Archive.ndf',
    SIZE = 2048KB
) TO FILEGROUP [FG_inventory_Archive];

ALTER DATABASE DataMartInventory ADD FILE
(
    NAME = N'inventory_2021',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\inventory_2021.ndf',
    SIZE = 2048KB
) TO FILEGROUP [FG_inventory_2021];

ALTER DATABASE DataMartInventory ADD FILE
(
    NAME = N'inventory_2022',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\inventory_2022.ndf',
    SIZE = 2048KB
) TO FILEGROUP [FG_inventory_2022];

ALTER DATABASE DataMartInventory ADD FILE
(
    NAME = N'inventory_2023',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\inventory_2023.ndf',
    SIZE = 2048KB
) TO FILEGROUP [FG_inventory_2023];

-- Create partition scheme
CREATE PARTITION SCHEME inventoryPartitionScheme
AS PARTITION InventoryDatePartitionFunction
TO ([Primary], [FG_inventory_2021], [FG_inventory_2022], [FG_inventory_2023]);

-- Drop existing view if it exists
IF OBJECT_ID('inventoryFactWithDateBase', 'V') IS NOT NULL
    DROP VIEW inventoryFactView;

-- Create a view to extract the required data
CREATE VIEW inventoryFactView
AS
SELECT
    inf.InventoryID,
    inf.DateID,
    inf.ProductID,
    inf.SupplierID,
    inf.StockReceived,
    inf.StockSold,
    inf.StockOnHand,
    dd.Date AS InventoryDate
FROM
    InventoryFact inf
JOIN
    DimDate dd ON inf.DateID = dd.DateID;
DROP TABLE Inventory_Fact
-- Create the partitioned table with foreign key constraints
CREATE TABLE Inventory_Fact
(
    InventoryID INT,
    DateID INT,
    ProductID INT,
    SupplierID INT,
    StockReceived INT,
    StockSold INT,
    StockOnHand INT,
    InventoryDate DATE,
    PRIMARY KEY (InventoryID, InventoryDate),
    CONSTRAINT FK_DateID FOREIGN KEY (DateID) REFERENCES DimDate(DateID) ON DELETE CASCADE,
    CONSTRAINT FK_ProductID FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID) ON DELETE CASCADE,
    CONSTRAINT FK_SupplierID FOREIGN KEY (SupplierID) REFERENCES DimSupplier(SupplierID) ON DELETE CASCADE
)
ON inventoryPartitionScheme (InventoryDate);


-- Insert data into the partitioned table
INSERT INTO Inventory_Fact (InventoryID, DateID, ProductID, SupplierID, StockReceived, StockSold, StockOnHand, InventoryDate)
SELECT InventoryID, DateID, ProductID, SupplierID, StockReceived, StockSold, StockOnHand, InventoryDate
FROM inventoryFactView;

-- Display partition information
SELECT 
    p.partition_number AS partition_number,
    f.name AS file_group, 
    p.rows AS row_count
FROM sys.partitions p
JOIN sys.destination_data_spaces dds ON p.partition_number = dds.destination_id
JOIN sys.filegroups f ON dds.data_space_id = f.data_space_id
WHERE OBJECT_NAME(OBJECT_ID) = 'Inventory_Fact'
ORDER BY partition_number;
SELECT * FROM sys.filegroups;