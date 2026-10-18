-- Revenue and Growth
-- Q1: How much revenue, variable cost, and gross profit did the retailer generate?
-- Sol'n: Create columns for revenue, variable cost, and gross profit across all valid sales records.
-- In SQL: Create a view which serve as baseline for solving future KPIs.

IF OBJECT_ID('ge.vw_sales_products_fact', 'V') IS NOT NULL
	DROP VIEW ge.vw_sales_products_fact;					-- This code is an effecient way to drop and update views
GO

-- View for solving the revenue, variable cost, gross profit.
CREATE OR ALTER VIEW ge.vw_sales_products_fact AS
(
SELECT
	p.Product_Name, p.Brand, p.Category, p.Subcategory,
    p.Unit_Cost_USD, p.Unit_Price_USD,
	s.Order_Number, s.Line_Item, s.Order_Date, s.Delivery_Date,
    s.CustomerKey, s.StoreKey, s.ProductKey, s.Quantity, s.Currency_Code,
	p.Unit_Price_USD * s.Quantity AS Revenue,
	p.Unit_Cost_USD * s.Quantity AS Variable_Cost,
	s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD) AS Gross_Profit
FROM ge.Sales AS s
LEFT JOIN ge.Products AS p
ON s.ProductKey = p.ProductKey
)
GO

-- Overall Table
SELECT *
FROM ge.vw_sales_products_fact;

-- Q2: Are there any duplicated rows between the sales table and the view table?
-- Sol'n: Check if there are duplicated rows by counting the rows of sales table and view table.
SELECT
	(SELECT COUNT(*) FROM ge.sales) AS sales_rows,
	(SELECT COUNT(*) FROM ge.vw_sales_products_fact) AS view_rows;

-- Q3: Are there NULLs Revenue, Variable Cost, and Gross Profit?
-- Sol'n: Check if there are NULLS in Revenue, Variable Cost and Gross Profit by counting the rows whose value are NULLS
SELECT
	COUNT(*) AS NULL_rows
FROM ge.vw_sales_products_fact
WHERE Revenue IS NULL AND Variable_Cost IS NULL AND Gross_Profit IS NULL;

-- Q4: How many missing or invalid rows that Unit_Cost_USD had?
-- Sol'n: Check if there are NULLS in Unit_Cost_USD

-- Counts how many NULL rows Unit_Cost_USD have
SELECT
	COUNT(*) AS total_NULL_rows
FROM ge.Products
WHERE Unit_Cost_USD IS NULL;

-- Lists down all the NULL rows by productkey and product name
SELECT
	ProductKey,
	Product_Name,
	Unit_Cost_USD,
	Unit_Price_USD
FROM ge.products
WHERE Unit_Cost_USD IS NULL
ORDER BY ProductKey;

-- If there were NULLS Run this (Check 00_clean_NULLS for the entire process)
UPDATE p
SET p.Unit_Cost_USD  = TRY_CONVERT(money, REPLACE(REPLACE(LTRIM(RTRIM(ps.Unit_Cost_USD)),  '$', ''), ',', '')),
    p.Unit_Price_USD = TRY_CONVERT(money, REPLACE(REPLACE(LTRIM(RTRIM(ps.Unit_Price_USD)), '$', ''), ',', ''))
FROM ge.Products AS p
JOIN ge.Products_staging AS ps
  ON TRY_CONVERT(int, ps.ProductKey) = p.ProductKey;

-- Check first and last date of orders for both the sales and view tables.

-- Sales table
SELECT
	MIN(Order_Date) AS First_date,
	MAX(Order_Date) AS Last_date
FROM ge.Sales;

-- View table
SELECT
	MIN(Order_Date) AS First_date,
	MAX(Order_Date) AS Last_date
FROM ge.vw_sales_products_fact;

-- Check for Negative Values in column Profit
SELECT
	COUNT(Gross_Profit) AS Profit_Loss
FROM ge.vw_sales_products_fact
WHERE Gross_Profit < 0;

-- Are there any duplicated product keys in products table?
SELECT ProductKey, COUNT(*) AS num_of_dupes FROM ge.Products GROUP BY ProductKey HAVING COUNT(*) > 1