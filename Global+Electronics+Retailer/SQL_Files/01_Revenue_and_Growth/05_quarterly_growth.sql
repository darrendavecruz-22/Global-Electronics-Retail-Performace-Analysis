/* =============================================================================
   Query: Quarterly Growth (QoQ)

   Purpose: Shows quarterly performance and how it changes from quarter to
   quarter (QoQ) and from the same quarter last year (YoY),
   including whether profit is growing faster or slower than revenue.

   Notes: Totals the sales fact view by quarter, calculates margin, order
   value, and units per order, then compares each quarter with the
   one before it (LAG of 1 row) and with the same quarter a year
   earlier (LAG of 4 rows).
   ============================================================================= */

WITH CTE_quarterly_growth AS
(
	SELECT
		YEAR(Order_Date) AS Year,
		DATEPART(quarter, Order_Date) AS Quarter,
		COUNT(DISTINCT MONTH(Order_Date)) AS Months_in_quarter,
		SUM(Revenue) AS Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		SUM(Quantity) AS Total_Units,
		COUNT(DISTINCT Order_Number) AS Total_Orders
	FROM ge.vw_sales_products_fact
	GROUP BY YEAR(Order_Date), DATEPART(quarter, Order_Date)
),

CTE_calc AS
(
	SELECT
		*,
		ROUND(100 * (Total_Profit / Total_Revenue), 2) AS Profit_Margin,
		ROUND((Total_Revenue / Total_Orders), 2) AS Avg_Order_Value,
		CAST(ROUND(1.0 * Total_Units / Total_Orders, 2) AS DECIMAL(5,2)) AS Units_per_Orders,
		ROUND(
			100 * (Total_Revenue - LAG(Total_Revenue) OVER(ORDER BY Year, Quarter)) / 
			NULLIF(LAG(Total_Revenue) OVER(ORDER BY Year, Quarter), 0), 2
		) AS qoq_Revenue,
		ROUND(
			100 * (Total_Profit - LAG(Total_Profit) OVER(ORDER BY Year, Quarter)) / 
			NULLIF(LAG(Total_Profit) OVER(ORDER BY Year, Quarter), 0), 2
		) AS qoq_Profit,
		CAST(ROUND(
			100.0 * (Total_Orders - LAG(Total_Orders) OVER(ORDER BY Year, Quarter)) / 
			NULLIF(LAG(Total_Orders) OVER(ORDER BY Year, Quarter), 0), 2
		) AS DECIMAL(10,2)) AS qoq_Orders,
		ROUND(
			100 * (Total_Revenue - LAG(Total_Revenue, 4) OVER(ORDER BY Year, Quarter)) / 
			NULLIF(LAG(Total_Revenue, 4) OVER(ORDER BY Year, Quarter), 0), 2
		) AS yoy_Revenue,
		ROUND(
			100 * (Total_Profit - LAG(Total_Profit, 4) OVER(ORDER BY Year, Quarter)) / 
			NULLIF(LAG(Total_Profit, 4) OVER(ORDER BY Year, Quarter), 0), 2)
		AS yoy_Profit
	FROM CTE_quarterly_growth
)

--Main Query
SELECT
	Year, Quarter, Months_in_quarter, Total_Revenue, Total_Profit, qoq_Revenue, qoq_Profit,
	qoq_Profit - qoq_Revenue AS Profit_and_Revenue_Gap,
	Profit_Margin,
	ROUND(Profit_Margin - LAG(Profit_Margin) OVER(ORDER BY Year, Quarter), 2) AS Margin_Change,
	Total_Orders, Total_Units, qoq_Orders, Avg_Order_Value,
	ROUND(
			100 * (Avg_Order_Value - LAG(Avg_Order_Value) OVER(ORDER BY Year, Quarter)) / 
			NULLIF(LAG(Avg_Order_Value) OVER(ORDER BY Year, Quarter), 0), 2
		) AS qoq_AOV,
	Units_per_Orders, yoy_Revenue, yoy_Profit
FROM CTE_calc
ORDER BY Year, Quarter;