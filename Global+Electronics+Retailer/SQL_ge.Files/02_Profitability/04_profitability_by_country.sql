-- 04_profitability_by_country

/*
Questions:
Q1: Which countries generate the most revenue and gross profit?
Q2: Which countries earn the most per customer and per order?
Q3: Which countries drove the revenue growth, and which drove the decline?
*/

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

-- Sol'n Q1 and Q2: Country summary
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

-- Sol'n Q4: Country growth and contribution to the overall change
WITH CTE_yearly AS
(
	SELECT
		YEAR(Order_Date) AS Year, Customer_Country AS Country, SUM(Revenue) AS Revenue
	FROM ge.vw_sales_products_countries_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY YEAR(Order_Date), Customer_Country
),

CTE_total_revenue_yearly AS
(
	SELECT
		*, SUM(Revenue) OVER(PARTITION BY Year) AS Yearly_Revenue
	FROM CTE_yearly
),

CTE_change AS
(
	SELECT
		Year, Country, Revenue,
		Revenue - LAG(Revenue) OVER(PARTITION BY Country ORDER BY Year) AS Revenue_change,
		LAG(Revenue) OVER(PARTITION BY Country ORDER BY Year) AS Prev_Revenue,
		LAG(Yearly_Revenue) OVER(PARTITION BY Country ORDER BY Year) AS Prev_Year_Revenue
	FROM CTE_total_revenue_yearly
)

SELECT
	Year, Country, Revenue, Revenue_change,
	CAST(ROUND(100.0 * Revenue_change / NULLIF(Prev_Revenue, 0), 2) AS DECIMAL(18,2)) AS Revenue_YoY,
	CAST(ROUND(100.0 * Revenue_change / NULLIF(Prev_Year_Revenue, 0), 2) AS DECIMAL(18,2)) AS Contribution_to_Growth,
	RANK() OVER(PARTITION BY Year ORDER BY Revenue_Change DESC) AS Growth_rank
FROM CTE_change
WHERE Revenue_change IS NOT NULL
ORDER BY Year, Growth_rank;