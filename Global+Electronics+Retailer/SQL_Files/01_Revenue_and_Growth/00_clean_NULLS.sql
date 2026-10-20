-- Check the root cause of the error, usually it is the dollar sign or comma or both.

-- Create a new products table and convert the data type into string
CREATE TABLE ge.Products_staging (
    ProductKey     nvarchar(20),
    Product_Name   nvarchar(200),
    Brand          nvarchar(100),
    Color          nvarchar(50),
    Unit_Cost_USD  nvarchar(30),
    Unit_Price_USD nvarchar(30),
    SubcategoryKey nvarchar(10),
    Subcategory    nvarchar(100),
    CategoryKey    nvarchar(10),
    Category       nvarchar(100)
);

-- Import the same values from products table using BULK INSERT
BULK INSERT ge.Products_staging
FROM 'C:\Users\Darren Cruz\Documents\Data Projects\Global+Electronics+Retailer\Products.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0d0a', CODEPAGE = '65001');

-- Check Products_staging and Products if they have same no. of rows
SELECT 
    (SELECT COUNT(*) FROM ge.Products_staging) AS ps_rows,
    (SELECT COUNT(*) FROM ge.Products) AS p_rows;

-- Check if there are now values for ProductKey 1897
SELECT Unit_Cost_USD, Unit_Price_USD
FROM ge.Products_staging WHERE ProductKey = '1897'; -- Originally, the Unit_Cost_USD of ProductKey 1897 was NULL.

-- Update the Products table by removing the dollar signs and commas, 
-- Replace the NULLs with string values from Product_staging using JOIN.
-- Use TRY_CONVERT when converting int or money into a string.

UPDATE p
SET p.Unit_Cost_USD = TRY_CONVERT(money, REPLACE(REPLACE(LTRIM(RTRIM(ps.Unit_Cost_USD)), '$', ''), ',', '')),
    p.Unit_Price_USD = TRY_CONVERT(money, REPLACE(REPLACE(LTRIM(RTRIM(ps.Unit_Price_USD)), '$', ''), ',', ''))
FROM ge.Products AS p
JOIN ge.Products_staging AS ps
ON TRY_CONVERT(int, ps.ProductKey) = p.ProductKey;

-- Check if there are still NULLS using the CASE statements.
SELECT
    SUM(CASE WHEN Unit_Cost_USD  IS NULL THEN 1 ELSE 0 END) AS null_cost,
    SUM(CASE WHEN Unit_Price_USD IS NULL THEN 1 ELSE 0 END) AS null_price
FROM ge.Products;

SELECT p.ProductKey, s.Unit_Cost_USD AS raw_cost, s.Unit_Price_USD AS raw_price
FROM ge.Products p
JOIN ge.Products_staging s ON TRY_CONVERT(int, s.ProductKey) = p.ProductKey
WHERE p.Unit_Cost_USD IS NULL OR p.Unit_Price_USD IS NULL;