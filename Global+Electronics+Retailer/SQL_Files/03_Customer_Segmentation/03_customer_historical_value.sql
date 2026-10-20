/* -----------------------------------------------------------------------------
   Query: Overall historical customer value
   Purpose: Summarizes what a typical customer is worth over their whole
   history, and how many customers come back.

   Notes: Calculates the median and 90th percentile of customer profit,
   then summarizes the customer base in one row. Totals cover each
   customer's full order history.
   ----------------------------------------------------------------------------- */


-- Overall historical value
WITH CTE_percentile AS
(
	SELECT
		Orders, Revenue, Profit,
		-- Median
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Profit DESC) OVER() AS Median_Profit,
		-- 90th Percentile
		PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Profit DESC) OVER() AS P90_Profit
	FROM ge.vw_customer_summary
)
-- Main query
SELECT
	-- Customer count
	COUNT(*) AS Customers,
	-- Average revenue and profit
	AVG(Revenue) AS Revenue,
	AVG(Profit) AS Profit,
	-- Median profit per customer and 90th percentile profit per customer
	MAX(Median_Profit) AS Median_Profit,
	MAX(P90_Profit) AS P90_Profit,
	-- Average orders per customer and average order value
	CAST(ROUND(AVG(1.0 * Orders), 2) AS DECIMAL(18,2)) AS Avg_orders_per_customer,
	CAST(ROUND(SUM(Revenue) / SUM(Orders), 2) AS DECIMAL(18,2)) AS Avg_order_value,
	-- Percentage of repeat customers
	CAST(ROUND(100.0 * SUM(CASE WHEN Orders > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(18,2)) AS Pct_Repeat_Customers
FROM CTE_percentile;


/* -----------------------------------------------------------------------------
   Query: Cohort value by acquisition year
   Purpose: Compares customers by the year of their first order, using only
   their first 12 months, to see whether newer customers are worth
   more or less than older ones.

   Notes: Each customer is measured over the 365 days after their first
   order, so older cohorts do not look better just because they
   had more time.

   Cohort value: Compares each acquisition year on its first 12 months only, 
   so older cohorts do not look better just because they had more time. 
   Cohorts that have not had 12 full months before the last order date are excluded.
   ----------------------------------------------------------------------------- */

-- Cohort value: Compares each acquisition year on its first 12 months only, so older
-- cohorts do not look better just because they had more time. Cohorts that have not
-- had 12 full months before the last order date are excluded.
WITH CTE_cohort AS
(
	SELECT
		cs.CustomerKey,
		YEAR(cs.First_Order_Date) AS Cohort_date,
		cs.Profit AS Lifetime_profit,
		-- First 12 month profit
		SUM(CASE WHEN sp.Order_Date < DATEADD(day, 365, cs.First_Order_Date) THEN sp.Gross_Profit ELSE 0 END) AS First_12_month_profit,
		-- First 12 month orders
		COUNT(DISTINCT CASE WHEN sp.Order_Date < DATEADD(day, 365, cs.First_Order_Date) THEN sp.Order_Number ELSE NULL END) AS First_12_month_orders
	FROM ge.vw_customer_summary AS cs
	JOIN ge.vw_sales_products_fact AS sp ON cs.CustomerKey = sp.CustomerKey
	WHERE cs.First_Order_Date <= DATEADD(day, -365, cs.Ref_date) -- Filters out all the customers who haven't been around in a full year
	GROUP BY cs.CustomerKey, YEAR(cs.First_Order_Date), cs.Profit
)
-- Main Query
SELECT
	Cohort_date,
	-- Customer count
	COUNT(*) AS Customers,
	-- Average of the first year profit and Average of the first year orders
	AVG(First_12_month_profit) AS Avg_first_year_profit,
	CAST(ROUND(AVG(1.0 * First_12_month_orders), 2) AS DECIMAL(18,2)) AS Avg_first_year_orders,
	-- Average lifetime profit and Percentage of the lifetime profit in the first year
	AVG(Lifetime_profit) AS Avg_lifetime_profit,
	CAST(ROUND(100.0 * SUM(First_12_month_profit) / SUM(Lifetime_profit), 2) AS DECIMAL(18,2)) AS Pct_lifetime_profit_in_1_year
FROM CTE_cohort
GROUP BY Cohort_date
ORDER BY Cohort_date;