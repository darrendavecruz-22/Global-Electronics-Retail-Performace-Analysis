/* -----------------------------------------------------------------------------
   Query: Top 20 customers by profit
   Purpose: Lists the 20 most profitable customers with their profile,
   order activity, and share of total business profit.

   Notes: Ranks every customer by lifetime profit and keeps the top 20.
   Profit_share is calculated over all customers before TOP 20 is
   applied. Totals cover each customer's full order history. 
   Results are sorted from the highest to the lowest profit.
   ----------------------------------------------------------------------------- */

-- Top 20 customers
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

-- Additional: Top 20 customers vs. Average customers
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