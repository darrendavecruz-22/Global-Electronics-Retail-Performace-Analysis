/* =============================================================================
   View: ge.vw_customer_rfm
   Purpose: Scores every customer on Recency, Frequency, and Monetary value
			(RFM) and assigns each one to a customer segment.

   Segment rules:
	Champions        R >= 4 and F >= 4
	Loyal            R >= 3 and F >= 3
	Recent Customers R >= 4 and F <= 2
	At Risk          R <= 2 and F >= 3
	Needs Attention  R = 3  and F <= 2
	Lapsed			 everything else
   ============================================================================= */
CREATE OR ALTER VIEW ge.vw_customer_rfm AS 
WITH CTE_base AS
(
	SELECT 
		CustomerKey, Name, Country, Continent, Orders, Revenue, Profit,
		DATEDIFF(day, Last_Order_Date, Ref_Date) AS Recency_Days
	FROM ge.vw_customer_summary
),

CTE_score As
(
	SELECT
		*,
		-- Recency Score: 1 = Oldest order and 5 = Newest order
		NTILE(5) OVER(ORDER BY Recency_Days DESC, CustomerKey) AS R_score,
		-- Frequency Score: Number of orders with 1 is the least and +5 is the most
		CASE WHEN Orders >= 5 THEN 5 ELSE Orders END AS F_score,
		-- Monetary Value Score: 1 is the lowest profit and 5 is the highest
		NTILE(5) OVER(ORDER BY Profit, CustomerKey) AS M_score
	FROM CTE_base
)

-- Main Query
SELECT
	*,
	-- RFM Segment: Champions, Loyal, Recent customers, At risk, Needs Attention, Lapsed
	CASE
		WHEN R_score >= 4 AND F_score >= 4 THEN 'Champions'
		WHEN R_score >= 3 AND F_score >= 3 THEN 'Loyal'
		WHEN R_score >= 4 AND F_score <= 2 THEN 'Recent Customers'
		WHEN R_score <= 2 AND F_score >= 3 THEN 'At Risk'
		WHEN R_score = 3 AND F_score <= 2 THEN 'Needs Attention'
		ELSE 'Lapsed'
	END AS RFM_Segment
FROM CTE_score
GO