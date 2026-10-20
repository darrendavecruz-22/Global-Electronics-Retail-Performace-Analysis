/* -----------------------------------------------------------------------------
   Query: Country performance summary
   Purpose: Compares countries on customers, orders, revenue, profit, margin,
   share of the business, and value per customer and per order.

   Notes: Groups the sales lines by the customer's country for 2016 to
   2020 and calculates totals, margin, shares, and per-customer
   and per-order values. Countries describe where customers live,
   not where the store is. Results are sorted from the highest to the 
   lowest profit.
   ----------------------------------------------------------------------------- */

-- Check 1: no rows lost or duplicated, and no sales without a country
SELECT
	(SELECT COUNT(*) FROM ge.vw_sales_products_fact) AS Fact_rows,
	COUNT(*) AS Joined_Rows,
	SUM(CASE WHEN Customer_Country IS NULL THEN 1 ELSE 0 END) AS Rows_without_Country
FROM ge.vw_sales_products_countries_fact;

-- Check 2: Match total
SELECT
	SUM(Revenue) AS Total_Revenue,
	SUM(Gross_Profit) AS Total_Profit
FROM ge.vw_sales_products_countries_fact
WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020;

-- Main query
SELECT
	Customer_Country AS Country,
	Customer_Continent AS Continent,
	
	-- Active Customers and Total orders
	COUNT(DISTINCT CustomerKey) AS Active_Customers,
	COUNT(DISTINCT Order_Number) AS Orders,

	-- Total revenue, profit, units sold, and profit margin
	SUM(Quantity) AS Units_Sold,
	SUM(Revenue) AS Revenue,
	SUM(Gross_Profit) AS Profit,
	CAST(ROUND(100.0 * SUM(Gross_Profit) / SUM(Revenue), 2) AS DECIMAL(18,2)) AS Profit_Margin,

	-- Revenue share, Profit share, and Profit rank
	CAST(ROUND(100.0 * SUM(Revenue) / SUM(SUM(Revenue)) OVER(), 2) AS DECIMAL(18,2)) AS Revenue_Share,
	CAST(ROUND(100.0 * SUM(Gross_Profit) / SUM(SUM(Gross_Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_Share,
	RANK() OVER(ORDER BY SUM(Gross_Profit) DESC) AS Profit_Rank,

	-- Profit per customer, Profit per order, Average order value, Orders per customer.
	CAST(ROUND(1.0 * SUM(Gross_Profit) / COUNT(DISTINCT CustomerKey), 2) AS DECIMAL(18,2)) AS Profit_per_customer,
	CAST(ROUND(1.0 * SUM(Gross_Profit) / COUNT(DISTINCT Order_Number), 2) AS DECIMAL(18,2)) AS Profit_per_order,
	CAST(ROUND(1.0 * SUM(Revenue) / COUNT(DISTINCT Order_Number), 2) AS DECIMAL(18,2)) AS Average_order_value,
	CAST(ROUND(1.0 * COUNT(DISTINCT Order_Number) / COUNT(DISTINCT CustomerKey), 2) AS DECIMAL(18,2)) AS Orders_per_customer
FROM ge.vw_sales_products_countries_fact
WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
GROUP BY Customer_Country, Customer_Continent
ORDER BY Profit DESC;