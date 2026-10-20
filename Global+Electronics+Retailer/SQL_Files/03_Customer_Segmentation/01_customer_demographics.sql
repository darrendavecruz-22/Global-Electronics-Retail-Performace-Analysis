/* -----------------------------------------------------------------------------
   Query: Age bracket performance summary
   Purpose: Compares customer age groups on customers, orders, revenue,profit,
   margin, share of the business, and value per customer.

   Notes: Groups the customer summary view by age bracket and calculates
   totals, margin, shares, and per-customer values. Age is
   measured on the latest order date in the data, and the totals
   cover each customer's full order history. Results are
   sorted from the youngest to the oldest bracket
   ----------------------------------------------------------------------------- */

-- Check 1: no customers lost in the join, and totals match the fact view.
SELECT
	(SELECT COUNT(DISTINCT CustomerKey) FROM  ge.vw_sales_products_fact) AS Customers_fact,
	(SELECT COUNT(DISTINCT CustomerKey) FROM ge.Customers) AS Customers_table,
	COUNT(*) AS Customers_summary,
	(SELECT SUM(Revenue) FROM ge.vw_sales_products_fact) AS Revenue_fact,
	SUM(Revenue) AS Revenue_summary,
	(SELECT SUM(Gross_Profit) FROM ge.vw_sales_products_fact) AS Profit_fact,
	SUM(Profit) AS Profit_summary
FROM ge.vw_customer_summary;

-- Expected: Customers_fact = Customers_summary and Revenue_fact = Revenue_summary
-- Customers_table maybe larger than from fact and summary since some customers never placed an order.

-- Check 2: sanity of age and gender values
SELECT
	MIN(Age) AS Youngest, MAX(Age) AS Oldest, AVG(Age) AS Avg_age,
	COUNT(DISTINCT Gender) AS Gender_count,
	SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS NULL_gender
FROM ge.vw_customer_summary;

-- Main Query
SELECT
	Age_bracket,

	-- Customer count and Order count
	COUNT(*) AS Customers,
	SUM(Orders) AS Orders,

	-- Revenue, Profit, Profit Margin
	SUM(Revenue) AS Revenue,
	SUM(Profit) AS Profit,
	CAST(ROUND(100.0 * SUM(Profit) / SUM(Revenue), 2) AS DECIMAL(18,2)) AS Gross_Margin,

	-- Customer share and Profit share
	CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS DECIMAL(18,2)) AS Customer_share,
	CAST(ROUND(100.0 * SUM(Profit) / SUM(SUM(Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_share,

	-- Profit per customers, Orders per customers, and Average order value.
	CAST(ROUND(1.0 * SUM(Profit) / COUNT(*), 2) AS DECIMAL(18,2)) AS Profit_per_customers,
	CAST(ROUND(1.0 * SUM(Orders) / COUNT(*), 2) AS DECIMAL(18,2)) AS Orders_per_customers,
	CAST(ROUND(1.0 * SUM(Revenue) / SUM(Orders), 2) AS DECIMAL(18,2)) AS Avg_order_value

FROM ge.vw_customer_summary
GROUP BY Age_bracket, Age_bracket_order
ORDER BY Age_bracket_order;

-- Additional: Gender
SELECT
	Gender,

	-- Customer count and Order count
	COUNT(*) AS Customers,
	SUM(Orders) AS Orders,

	-- Revenue, Profit, Profit Margin
	SUM(Revenue) AS Revenue,
	SUM(Profit) AS Profit,
	CAST(ROUND(100.0 * SUM(Profit) / SUM(Revenue), 2) AS DECIMAL(18,2)) AS Gross_Margin,

	-- Customer share and Profit share
	CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS DECIMAL(18,2)) AS Customer_share,
	CAST(ROUND(100.0 * SUM(Profit) / SUM(SUM(Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_share,

	-- Profit per customers, Orders per customers, and Average order value.
	CAST(ROUND(1.0 * SUM(Profit) / COUNT(*), 2) AS DECIMAL(18,2)) AS Profit_per_customers,
	CAST(ROUND(1.0 * SUM(Orders) / COUNT(*), 2) AS DECIMAL(18,2)) AS Orders_per_customers,
	CAST(ROUND(1.0 * SUM(Revenue) / SUM(Orders), 2) AS DECIMAL(18,2)) AS Avg_order_value

FROM ge.vw_customer_summary
GROUP BY Gender
ORDER BY Profit DESC;