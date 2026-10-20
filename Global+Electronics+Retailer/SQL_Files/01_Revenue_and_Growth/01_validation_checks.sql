-- Revenue and Growth
-- How much revenue, variable cost, and gross profit did the retailer generate?

-- Are there any duplicated rows between the sales table and the view table?
-- Check if there are duplicated rows by counting the rows of sales table and view table.
SELECT
	(SELECT COUNT(*) FROM ge.sales) AS sales_rows,
	(SELECT COUNT(*) FROM ge.vw_sales_products_fact) AS view_rows;

-- Are there NULLs Revenue, Variable Cost, and Gross Profit?
-- Check if there are NULLS in columns Revenue, Variable Cost and Gross Profit by counting the rows whose value are NULLS
SELECT
	COUNT(*) AS NULL_rows
FROM ge.vw_sales_products_fact
WHERE Revenue IS NULL AND Variable_Cost IS NULL AND Gross_Profit IS NULL;

-- How many missing or invalid rows that Unit_Cost_USD had?
-- Check if there are NULLS in Unit_Cost_USD
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