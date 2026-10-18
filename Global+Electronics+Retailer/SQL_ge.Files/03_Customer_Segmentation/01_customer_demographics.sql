-- 01_customer_demographics

/*
Questions:
Q1: Which age bracket generate the most profit, and how much does each customer bring in?
Q2: Do male and female customers differ in spend and profit?
Q3: Which continents contribute the most profit, and which have the most valuable customers?
*/

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

-- Sol'n Q1: Age bracket
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

-- Sol'n 2: Gender
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

-- Sol'n 3: Continent
SELECT
	Continent,

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
GROUP BY Continent
ORDER BY Profit DESC;

-- Optional: Country
SELECT
	Country,

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
GROUP BY Country
ORDER BY Profit DESC;