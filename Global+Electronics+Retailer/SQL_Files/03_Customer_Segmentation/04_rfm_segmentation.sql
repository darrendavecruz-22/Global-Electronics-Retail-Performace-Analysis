/* -----------------------------------------------------------------------------
   Query: RFM segment summary
   Purpose: Compares the RFM customer segments on size, revenue, profit,
   and buying behavior, and suggests an action for each segment.

   Notes: Groups the RFM view by segment and calculates size, profit
   share, and per-customer values. Suggested_Action is a fixed label for each
   segment to guide customer retention and marketing decisions.
   Results are sorted from the highest to the lowest profit.
   ----------------------------------------------------------------------------- */

-- Check if all customers scored, and what each score means in real terms
SELECT
	R_Score,
	COUNT(*)           AS Customers,
	MIN(Recency_Days)  AS Min_Days_Since_Last_Order,
	MAX(Recency_Days)  AS Max_Days_Since_Last_Order
FROM ge.vw_customer_rfm
GROUP BY R_Score
ORDER BY R_Score;
-- R_Score = 5 means that 2377 customers recently made an order (Last_Order_Date - Ref_Date = 0).

-- F Score
SELECT
	F_Score,
	COUNT(*)           AS Customers,
	CAST(ROUND(1.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS DECIMAL(18,2)) AS Share
FROM ge.vw_customer_rfm
GROUP BY F_Score
ORDER BY F_Score;


-- Main Query
SELECT
	RFM_Segment,
	-- Customer count and Customer share
	COUNT(*) AS Customers,
	CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS DECIMAL(18,2)) AS Customer_share,
	-- Revenue, Profit, and Profit share
	SUM(Revenue) AS Revenue, SUM(Profit) AS Profit,
	CAST(ROUND(100.0 * SUM(Profit) / SUM(SUM(Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_share,
	-- Profit per customer and Orders per customer
	CAST(ROUND(1.0 * SUM(Profit) / COUNT(*), 2) AS DECIMAL(18,2)) AS Profit_per_customer,
	CAST(ROUND(1.0 * SUM(Orders) / COUNT(*), 2) AS DECIMAL(18,2)) AS Orders_per_customer,
	-- Average order value and Average last day of order
	CAST(ROUND(1.0 * SUM(Revenue) / SUM(Orders), 2) AS DECIMAL(18,2)) AS Avg_order_value,
	AVG(Recency_Days) AS Avg_last_day_of_order,
	-- Suggested Action
	CASE RFM_Segment
		WHEN 'Champions' THEN 'Reward and retain: early access, loyalty perks'
		WHEN 'Loyal' THEN 'Upsell and cross-sell; keep engaged'
		WHEN 'Recent customers' THEN 'Encourage a second purchase soon'
		WHEN 'At risk' THEN 'Win-back campaign: they used to buy often'
		WHEN 'Needs attention' THEN 'Reminder or offer before they lapse'
		ELSE 'Low-cost reactivation only; do not over-invest'
	END AS Suggested_Action
FROM ge.vw_customer_rfm
GROUP BY RFM_Segment
ORDER BY Profit DESC;