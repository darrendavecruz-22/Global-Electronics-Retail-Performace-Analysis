-- 03_customer_concentration

/*
Questions:
Q1: What share of profit comes from the top 1%, 5%, 10%, and 20% of customers?
Q2: How is profit spread across customer deciles (the full distribution)?
*/

-- Sol'n Q1: Profit and revenue share of the top customers
WITH CTE_rank AS
(
	SELECT
		CustomerKey, Revenue, Profit,
		ROW_NUMBER() OVER(ORDER BY Profit DESC, CustomerKey) AS rn,
		COUNT(*) OVER() AS Customer_count
	FROM ge.vw_customer_summary
)

-- Main Query
-- Top 1% of Customer
SELECT
	'Top 1% of Customers' AS Customer_group,
	SUM(CASE WHEN rn <= CEILING(0.01 * Customer_count) THEN 1 ELSE 0 END) AS Customers, -- Rows for Top 1% customers

	-- Profit share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn <= CEILING(0.01 * Customer_count) THEN Profit ELSE 0 END) /
			SUM(Profit), 2) AS DECIMAL(18,2)) AS Profit_share,
	-- Revenue share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn <= CEILING(0.01 * Customer_count) THEN Revenue ELSE 0 END) /
			SUM(Revenue), 2) AS DECIMAL(18,2)) AS Revenue_share
FROM CTE_rank

UNION ALL

-- Top 5% of Customer
SELECT
	'Top 5% of Customers' AS Customer_group,
	SUM(CASE WHEN rn <= CEILING(0.05 * Customer_count) THEN 1 ELSE 0 END) AS Customers, -- Rows for Top 5% customers

	-- Profit share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn <= CEILING(0.05 * Customer_count) THEN Profit ELSE 0 END) /
			SUM(Profit), 2) AS DECIMAL(18,2)) AS Profit_share,
	-- Revenue share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn <= CEILING(0.05 * Customer_count) THEN Revenue ELSE 0 END) /
			SUM(Revenue), 2) AS DECIMAL(18,2)) AS Revenue_share
FROM CTE_rank

UNION ALL

-- Top 10% of Customer
SELECT
	'Top 10% of Customers' AS Customer_group,
	SUM(CASE WHEN rn <= CEILING(0.1 * Customer_count) THEN 1 ELSE 0 END) AS Customers, -- Rows for Top 10% customers

	-- Profit share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn <= CEILING(0.1 * Customer_count) THEN Profit ELSE 0 END) /
			SUM(Profit), 2) AS DECIMAL(18,2)) AS Profit_share,
	-- Revenue share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn <= CEILING(0.1 * Customer_count) THEN Revenue ELSE 0 END) /
			SUM(Revenue), 2) AS DECIMAL(18,2)) AS Revenue_share
FROM CTE_rank

UNION ALL

-- Top 20% of Customer
SELECT
	'Top 20% of Customers' AS Customer_group,
	SUM(CASE WHEN rn <= CEILING(0.2 * Customer_count) THEN 1 ELSE 0 END) AS Customers, -- Rows for Top 20% customers

	-- Profit share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn <= CEILING(0.2 * Customer_count) THEN Profit ELSE 0 END) /
			SUM(Profit), 2) AS DECIMAL(18,2)) AS Profit_share,
	-- Revenue share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn <= CEILING(0.2 * Customer_count) THEN Revenue ELSE 0 END) /
			SUM(Revenue), 2) AS DECIMAL(18,2)) AS Revenue_share
FROM CTE_rank

UNION ALL

-- Bottom 50% of Customer
SELECT
	'Bottom 50% of Customers' AS Customer_group,
	SUM(CASE WHEN rn > CEILING(Customer_count / 2.0) THEN 1 ELSE 0 END) AS Customers, -- Rows for Bottom 50% customers

	-- Profit share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn > CEILING(Customer_count / 2.0) THEN Profit ELSE 0 END) /
			SUM(Profit), 2) AS DECIMAL(18,2)) AS Profit_share,
	-- Revenue share
	CAST(ROUND(
			100.0 * SUM(CASE WHEN rn > CEILING(Customer_count / 2.0) THEN Revenue ELSE 0 END) /
			SUM(Revenue), 2) AS DECIMAL(18,2)) AS Revenue_share
FROM CTE_rank;

-- Sol'n Q2: Decile table
WITH CTE_decile AS
(
	SELECT
		NTILE(10) OVER(ORDER BY Profit DESC, CustomerKey) AS Decile,
		CustomerKey, Orders, Revenue, Profit
	FROM ge.vw_customer_summary
),

CTE_aggregate AS
(
	SELECT
		Decile,
		COUNT(*) AS Customers,
		SUM(Orders) AS Orders,
		SUM(Revenue) AS Revenue,
		SUM(Profit) AS Profit,
		MIN(Profit) AS Lowest_Profit,
		MAX(Profit) AS Highest_Profit
	FROM CTE_decile
	GROUP BY Decile
)

-- Main Query
SELECT
	Decile, Customers, Profit,

	-- Profit share
	CAST(ROUND(100.0 * Profit / SUM(Profit) OVER(), 2) AS DECIMAL(18,2)) AS Profit_share,

	-- Cumulative share of profit
	CAST(ROUND(100.0 * SUM(Profit) OVER(ORDER BY Decile ROWS UNBOUNDED PRECEDING) / SUM(Profit) OVER(), 2) AS DECIMAL(18,2)) AS Cumulative_share,

	-- Profit per customer
	CAST(ROUND(1.0 * Profit / Customers, 2) AS DECIMAL(18,2)) AS Profit_per_customer,
	
	-- Lowest and Highest profit
	Lowest_Profit, Highest_Profit,

	-- Orders per customer and average order value
	CAST(ROUND(1.0 * Orders / Customers, 2) AS DECIMAL(18,2)) AS Orders_per_customer,
	CAST(ROUND(1.0 * Revenue / Orders, 2) AS DECIMAL(18,2)) AS Avg_order_value

FROM CTE_aggregate
ORDER BY Decile;