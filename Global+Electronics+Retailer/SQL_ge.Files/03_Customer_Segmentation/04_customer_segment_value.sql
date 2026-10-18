-- 04_customer_segment_value

/*
Questions:
Q1: Which combined segments are worth the most per customer?
Q2: Which segments are both large and above-average in value, so they deserve marketing priority?
*/

-- Check: each dimension must cover every customer once
SELECT
	COUNT(*) AS Customer_count,
	CEILING(1.0 * COUNT(*)) AS Min_seg_size,
	SUM(Profit) AS Profit
FROM ge.vw_customer_summary;

-- Sol'n Q1 and Q2: Combined segment value
WITH CTE_segmentation AS
(
	-- Segement Age bracket and gender
	SELECT
		'Age Bracket & Gender' AS Dimension, CONCAT(Age_bracket, ' | ', Gender) AS Segment,
		CustomerKey, Orders, Revenue, Profit
	FROM ge.vw_customer_summary

	UNION ALL

	-- Segement Age bracket and continent
	SELECT
		'Age Bracket & Continent' AS Dimension, CONCAT(Age_bracket, ' | ', Continent) AS Segment,
		CustomerKey, Orders, Revenue, Profit
	FROM ge.vw_customer_summary

	UNION ALL

	-- Segement Age bracket and gender
	SELECT
		'Continent & Gender' AS Dimension, CONCAT(Continent, ' | ', Gender) AS Segment,
		CustomerKey, Orders, Revenue, Profit
	FROM ge.vw_customer_summary
),

CTE_aggregate AS
(
	SELECT
		Dimension, Segment,

		-- Customer count, orders, revenue, profit
		COUNT(*) AS Customer_count, SUM(Orders) AS Orders, 
		SUM(Revenue) AS Revenue, SUM(Profit) AS Profit,

		-- Shares and overall average before segmentation
		CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY Dimension), 2) AS DECIMAL(18,2)) AS Customer_share,
		CAST(ROUND(100.0 * SUM(Profit) / SUM(SUM(Profit)) OVER(PARTITION BY Dimension), 2) AS DECIMAL(18,2)) AS Profit_share,
		CAST(ROUND(1.0 * SUM(SUM(Profit)) OVER(PARTITION BY Dimension) / SUM(COUNT(*)) OVER(PARTITION BY Dimension), 2) AS DECIMAL(18,2)) AS Overall_share

	FROM CTE_segmentation
	GROUP BY Dimension, Segment
)

-- Main Query
SELECT
	Dimension, Segment, Customer_count, Customer_share, Profit_share,

	-- Profit per customers and Value Index
	CAST(ROUND(1.0 * Profit / Customer_count, 2) AS DECIMAL(18,2)) AS Profit_per_customer,
	CAST(ROUND(1.0 * Profit / Customer_count/ Overall_share, 2) AS DECIMAL(18,2)) AS Value_index,

	-- Orders per customer and Average order value
	CAST(ROUND(1.0 * Orders / Customer_count, 2) AS DECIMAL(18,2)) AS Orders_per_customer,
	CAST(ROUND(1.0 * Revenue / Orders, 2) AS DECIMAL(18,2)) AS Avg_order_value,

	-- Ranking of profit per customers
	RANK() OVER(PARTITION BY Dimension ORDER BY CAST(ROUND(1.0 * Profit / Customer_count, 2) AS DECIMAL(18,2)) DESC) AS Value_rank,
	CASE
		WHEN CAST(ROUND(1.0 * Profit / Customer_count/ Overall_share, 2) AS DECIMAL(18,2)) >= 1.05 THEN 'Above Average Value'
		WHEN CAST(ROUND(1.0 * Profit / Customer_count/ Overall_share, 2) AS DECIMAL(18,2)) <= 0.95 THEN 'Below Average Value'
		ELSE 'Near Average'
	END AS Value_class
FROM CTE_aggregate
ORDER BY Dimension, Value_rank;