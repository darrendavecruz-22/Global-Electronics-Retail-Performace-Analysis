-- 02_top_customers

/*
Questions:
Q1: Who are the top 20 customers by profit, and what do they look like?
Q2: How different is a top-20 customer from an average customer?
Q3: Are the top 100 customers concentrated in particular age brackets, genders, or continents?
Q4: Are the top 100 customers still active?
*/

-- Sol'n Q1: Top 20 customers
SELECT TOP 20
	RANK() OVER(ORDER BY cs.Profit) AS Profit_rank,

	-- Customer's attributes
	cs.CustomerKey,
	c.Name,
	cs.Country, cs.Continent, cs.Gender, cs.Age_bracket, cs.Orders, cs.Units_sold,

	-- Revenue and Profit
	cs.Revenue, cs.Profit,

	-- Average order value and Profit share
	CAST(ROUND(1.0 * cs.Revenue / cs.Orders, 2) AS DECIMAL(18,2)) AS Avg_order_value,
	CAST(ROUND(100.0 * cs. Profit / SUM(cs.Profit) OVER(), 2) AS DECIMAL(18,2)) AS Profit_share, -- SUM() OVER() is evaluated before TOP 20

	-- First and Last order date
	cs.First_Order_Date, cs.Last_Order_Date

FROM ge.vw_customer_summary AS cs
JOIN ge.Customers AS c ON cs.CustomerKey = c.CustomerKey
ORDER BY Profit DESC;

-- Sol'n Q2: Top 20 customers vs. Average customers
WITH CTE_rank AS
(
	SELECT
		*,
		ROW_NUMBER() OVER(ORDER BY Profit DESC, CustomerKey) AS rn
	FROM ge.vw_customer_summary
)
SELECT
	-- Segregate Top 20 customers to average customers.
	CASE WHEN rn <= 20 THEN 'Top 20' ELSE 'Average Customers' END AS Customer_seg,

	-- Average Profit and Orders
	AVG(Profit) AS Avg_profit,
	CAST(ROUND(AVG(1.0 * Orders), 2) AS DECIMAL(18,2)) AS Avg_orders,

	-- Average Order value and average units sold
	CAST(ROUND(1.0 * SUM(Revenue) / SUM(Orders), 2) AS DECIMAL(18,2)) AS Avg_order_value,
	CAST(ROUND(AVG(1.0 * Units_sold), 2) AS DECIMAL(18,2)) AS Avg_units_sold,

	-- Profit share
	CAST(ROUND(100.0 * SUM(Profit) / SUM(SUM(Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_share

FROM CTE_rank
GROUP BY CASE WHEN rn <= 20 THEN 'Top 20' ELSE 'Average Customers' END;
-- It turns out that top 20 customers buy more often than the average customers

-- Sol'n Q3: Segment the top 100 customers vs. all customers
WITH CTE_rank AS
(
	SELECT
		*,
		ROW_NUMBER() OVER(ORDER BY Profit DESC, CustomerKey) AS rn
	FROM ge.vw_customer_summary
),

CTE_segment AS -- Segment customers based on age bracket, gender, and continent
(
	SELECT 'Age bracket' AS Dimension, Age_bracket AS Segment, rn FROM CTE_rank -- Create rows for Age_bracket
	UNION ALL
	SELECT 'Gender', Gender, rn FROM CTE_rank -- Create rows for Gender
	UNION ALL
	SELECT 'Continent', Continent, rn FROM CTE_rank -- Create rows for Continent
)

-- Main Query
SELECT
	Dimension, Segment,

	-- Customer count and Top 100 customers
	COUNT(*) AS Customer_count,
	SUM(CASE WHEN rn <= 100 THEN 1 ELSE 0 END) AS Top_100,

	-- Overall share
	CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY Dimension), 2) AS DECIMAL(18,2)) AS Overall_share,

	-- Share of Top 100
	CAST(ROUND(100.0 * SUM(CASE WHEN rn <= 100 THEN 1 ELSE 0 END) / 
	SUM(SUM(CASE WHEN rn <= 100 THEN 1 ELSE 0 END)) OVER(PARTITION BY Dimension), 2) 
	AS DECIMAL(18,2)) AS Top_100_share,

	-- Share Gap
	CAST(ROUND(
				100.0 * COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY Dimension) -
				100.0 * SUM(CASE WHEN rn <= 100 THEN 1 ELSE 0 END) / SUM(SUM(CASE WHEN rn <= 100 THEN 1 ELSE 0 END)) OVER(PARTITION BY Dimension)
				, 2)
		AS DECIMAL(18,2)) AS Share_gap

FROM CTE_segment
GROUP BY Dimension, Segment
ORDER BY Dimension, Share_gap;

-- Sol'n Q4: Are the top 100 still active?
WITH CTE_rank AS
(
	SELECT
		*,
		ROW_NUMBER() OVER(ORDER BY Profit DESC, CustomerKey) AS rn
	FROM ge.vw_customer_summary
)

-- Main Query
SELECT 
	-- Separate Top 100 customers to the rest.
	CASE WHEN rn <= 100 THEN 'Top 100' ELSE 'All Others' END AS Customer_seg,

	-- Customer count
	COUNT(*) AS Customer_count,

	-- Customers who ordered for the last 12 months
	SUM(CASE WHEN DATEDIFF(day, Last_Order_Date, Ref_Date) <= 365 THEN 1 ELSE 0 END) AS Ordered_Last_12_months,

	-- Percentage of customers who are active last 12 months
	CAST(ROUND(
				100.0 * SUM(CASE WHEN DATEDIFF(day, Last_Order_Date, Ref_Date) <= 365 THEN 1 ELSE 0 END) /
				COUNT(*), 2)
		AS DECIMAL(18,2)) AS Active_Last_12_months,

	-- Average days since last order
	AVG(DATEDIFF(day, Last_Order_Date, Ref_Date)) AS Avg_days_last_ordered

FROM CTE_rank
GROUP BY CASE WHEN rn <= 100 THEN 'Top 100' ELSE 'All Others' END;