-- 07_customer_purchase_intervals

/*
Questions:
Q1: How many days typically pass between a customer's orders?
Q2: Does the gap shrink or grow as customers keep buying?
Q3: How quickly do customers place their second order?
*/

-- Check: the number of orders must equal the distinct orders in the fact view,
-- and customers with an interval must equal the repeat customers from file 06
SELECT
	COUNT(*) AS Orders_view,
	(SELECT COUNT(DISTINCT Order_Number) FROM ge.vw_sales_products_fact) AS Orders_fact,
	COUNT(DISTINCT CASE WHEN Order_days_gap IS NOT NULL THEN CustomerKey END) AS Repeat_customers
FROM ge.vw_customer_orders;

-- Sol'n Q1: Overall interval statistics
WITH CTE_percentile AS
(
	SELECT
		CustomerKey, Order_days_gap,
		-- P25, Median, P75, P90
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Order_days_gap) OVER() AS P25,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Order_days_gap) OVER() AS Median,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Order_days_gap) OVER() AS P75,
		PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY Order_days_gap) OVER() AS P90
	FROM ge.vw_customer_orders
	WHERE Order_days_gap IS NOT NULL
)

-- Main Query
SELECT
	-- Count the total order gaps
	COUNT(*) AS Total_order_gap,
	-- Repeat Customers
	COUNT(DISTINCT CustomerKey) AS Repeat_customers,
	-- Average days between orders
	CAST(ROUND(AVG(1.0 * Order_days_gap), 2) AS DECIMAL(18,2)) AS Avg_days_between_orders,
	-- P25, Median, P75, P90
	MAX(P25) AS P25_days, MAX(Median) AS Median_days, MAX(P75) AS P75_days, MAX(P90) AS P90_days,
	-- Percentage of same day orders
	CAST(ROUND(100.0 * SUM(CASE WHEN Order_days_gap = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(18,2)) AS Pct_same_day_orders
FROM CTE_percentile;

-- Sol'n Q2: Gap by order position (gap before the 2nd order, 3rd order, and so on)
WITH CTE_percentile AS
(
	SELECT
		-- Label order numbers as 1st, 2nd, 3rd,...
		CASE 
			WHEN Order_No >= 5 THEN '5th or later'
			ELSE CONCAT(Order_No, CASE WHEN Order_No = 2 THEN 'nd' WHEN Order_No = 3 THEN 'rd' ELSE 'th' END) 
		END AS Order_Position,
		-- Set the value of orders greater than 5 as 5
		CASE WHEN Order_No >= 5 THEN 5 ELSE Order_No END AS Sort_Key,
		Order_days_gap,
		-- Find the Median and Partition the values by Sort_Key
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Order_days_gap) OVER(PARTITION BY CASE WHEN Order_No >= 5 THEN 5 ELSE Order_No END) AS Median_gap
	FROM ge.vw_customer_orders
	WHERE Order_days_gap IS NOT NULL
)

-- Main Query
SELECT
	Order_Position,
	COUNT(*) AS Intervals,
	CAST(ROUND(AVG(1.0 * Order_days_gap), 2) AS DECIMAL(18,2))  AS Avg_Gap_Days,
	MAX(Median_Gap) AS Median_Gap_Days
FROM CTE_percentile
GROUP BY Order_Position, Sort_Key
ORDER BY Sort_Key;

-- Sol'n Q3: Time to second order
WITH CTE_second AS
(
	SELECT
		CASE
			WHEN Order_days_gap <= 30  THEN '1. 0-30 days'
			WHEN Order_days_gap <= 90  THEN '2. 31-90 days'
			WHEN Order_days_gap <= 180 THEN '3. 91-180 days'
			WHEN Order_days_gap <= 365 THEN '4. 181-365 days'
			ELSE                      '5. Over 365 days'
		END AS Time_to_Second_Order
	FROM ge.vw_customer_orders
	WHERE Order_No = 2
)
SELECT
	Time_to_Second_Order,
	COUNT(*) AS Customers,
	ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS Share_of_Repeat_Customers,
	ROUND(100.0 * SUM(COUNT(*)) OVER(ORDER BY Time_to_Second_Order ROWS UNBOUNDED PRECEDING)
	      / SUM(COUNT(*)) OVER(), 2) AS Cumulative_Share
FROM CTE_second
GROUP BY Time_to_Second_Order
ORDER BY Time_to_Second_Order;