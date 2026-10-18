-- 06_repeat_purchase_analysis

/*
Questions:
Q1: What share of customers buy more than once, and how much more are they worth?
Q2: How are customers spread by number of orders?
Q3: Which segments (age bracket, gender, continent) have the highest repeat rate?
Q4: Has the share of customers who repeat within 12 months changed across acquisition years?
*/

-- Sol'n Q1: One-time vs. repeat customers
SELECT
	-- Segregrate one-time customers to repeat customers
	CASE WHEN Orders = 1 THEN 'One-Time' ELSE 'Repeat' END AS Customer_type,
	-- Customer count
	COUNT(*) AS Customers,
	-- Customer share, revenue share, profit share
	CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS DECIMAL(18,2)) AS Customer_share,
	CAST(ROUND(100.0 * SUM(Revenue) / SUM(SUM(Revenue)) OVER(), 2) AS DECIMAL(18,2)) AS Revenue_share,
	CAST(ROUND(100.0 * SUM(Profit) / SUM(SUM(Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_share,
	-- Profit per customer, Orders per customer, Average order value
	CAST(ROUND(1.0 * SUM(Profit) / COUNT(*), 2) AS DECIMAL(18,2)) AS Profit_per_customer,
	CAST(ROUND(1.0 * SUM(Orders) / COUNT(*), 2) AS DECIMAL(18,2)) AS Orders_per_customer,
	SUM(Revenue) / SUM(Orders) AS Avg_order_value
FROM ge.vw_customer_summary
GROUP BY CASE WHEN Orders = 1 THEN 'One-Time' ELSE 'Repeat' END;

-- Sol'n Q2: Distribution by number of orders
SELECT
	-- Segregate customers with at least 5 orders
	CASE WHEN Orders >= 5 THEN '+5' ELSE CAST(Orders AS VARCHAR(2)) END AS Orders_placed,
	-- Customer count
	COUNT(*) AS Customers,
	-- Customer share and Profit share
	CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS DECIMAL(18,2)) AS Customer_Share,
	CAST(ROUND(100.0 * SUM(Profit) / SUM(SUM(Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_Share,
	-- Profit per customer
	CAST(ROUND(1.0 * SUM(Profit) / COUNT(*), 2) AS DECIMAL(18,2)) AS Profit_per_Customer
FROM ge.vw_customer_summary
GROUP BY CASE WHEN Orders >= 5 THEN '+5' ELSE CAST(Orders AS VARCHAR(2)) END
ORDER BY MIN(Orders);

-- Sol'n Q3: Repeat rate by segment
WITH CTE_segment AS
(
	SELECT 'Age Bracket' AS Dimension, Age_bracket AS Segment, Orders FROM ge.vw_customer_summary
	UNION ALL
	SELECT 'Gender', Gender, Orders FROM ge.vw_customer_summary
	UNION ALL
	SELECT 'Continent', Continent, Orders FROM ge.vw_customer_summary
),

CTE_aggregate AS
(
	SELECT
		Dimension, Segment,
		COUNT(*) AS Customers,
		SUM(CASE WHEN Orders > 1 THEN 1 ELSE 0 END) AS Repeat_Customers
	FROM CTE_segment
	GROUP BY Dimension, Segment
)

-- Main Query
SELECT
	Dimension, Segment, Customers, Repeat_Customers,
	-- Repeat rate
	CAST(ROUND(100.0 * Repeat_Customers / Customers, 2) AS DECIMAL(18,2)) AS Repeat_rate,
	-- Overall rate
	CAST(ROUND(100.0 * SUM(Repeat_Customers) OVER(PARTITION BY Dimension) / SUM(Customers) OVER(PARTITION BY Dimension), 2) AS DECIMAL(18,2)) AS Overall_rate,
	-- Repeat rate and Overall rate gap
	CAST(ROUND(
		100.0 * Repeat_Customers / Customers / 100.0 * SUM(Repeat_Customers) OVER(PARTITION BY Dimension) / SUM(Customers) OVER(PARTITION BY Dimension)
		, 2) AS DECIMAL(18,2)) AS Rate_gap
FROM CTE_aggregate
ORDER BY Dimension, Repeat_rate DESC;

-- Sol'n Q4: Repeat within 12 months, by acquisition year.
-- Only customers with a full 365 days of observation are included, so that
-- recent customers are not penalised for having had less time to come back.
WITH CTE_orders AS
(
	SELECT CustomerKey, Order_Number, MIN(Order_Date) AS Order_date
	FROM ge.vw_sales_products_fact
	GROUP BY CustomerKey, Order_Number
),

CTE_no_of_orders_per_customer AS
(
	SELECT
		CustomerKey, Order_date,
		ROW_NUMBER() OVER(PARTITION BY CustomerKey ORDER BY Order_Number, Order_date) AS Order_no
	FROM CTE_orders
),

CTE_customers AS
(
	SELECT
		n.CustomerKey,
		n.Order_date AS First_Order_Date,
		n1.Order_date AS Second_Order_Date,
		YEAR(n.Order_Date) AS Cohort_date
	FROM CTE_no_of_orders_per_customer AS n
	JOIN CTE_no_of_orders_per_customer AS n1 ON n.CustomerKey = n1.CustomerKey
	WHERE n.Order_no = 1 AND n.Order_date <= DATEADD(day, -365, (SELECT MAX(Order_Date) FROM ge.vw_sales_products_fact))
)

-- Main Query
SELECT
	Cohort_date,
	-- Customer count
	COUNT(*) AS Customers,
	-- Repeat orders within the same year (second purchase happened in less than 12 months)
	SUM(CASE WHEN Second_Order_Date <= DATEADD(day, 365, First_Order_Date) THEN 1 ELSE 0 END) AS Repeat_order_within_12M,
	-- Repeat purchase rate in less than 12 months
	CAST(ROUND(
		100.0 * SUM(CASE WHEN Second_Order_Date <= DATEADD(day, 365, First_Order_Date) THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(18,2)) AS Repeat_rate_12M

FROM CTE_customers
GROUP BY Cohort_date
ORDER BY Cohort_date;