/* =============================================================================
   Query: Month-over-Month (MoM)

   Purpose: Gives a general overview of year-over-year (YoY) performance:
   yearly totals, profit margin, and YoY growth in revenue, profit, and orders.

   Notes: Totals the sales fact view by month, then compares each month
   with the one before it (LAG of 1 row) and with the same month
   a year earlier (LAG of 12 rows).
   ============================================================================= */

WITH CTE_monthly_growth AS
(
	SELECT
		DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1) AS Start_of_Month, -- Takes the first day in the month
		SUM(Revenue) AS Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		SUM(Quantity) AS Total_Units,
		COUNT(DISTINCT Order_Number) AS Total_Orders
	FROM ge.vw_sales_products_fact
	GROUP BY DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1) -- Aggregate all of the first day in the month
)

-- Main Query 
SELECT * FROM
(
	SELECT
		Start_of_Month,
		Total_Orders,
		Total_Units,
		Total_Revenue,
		Total_Profit,
		ROUND((Total_Profit/Total_Revenue) * 100, 2) AS Profit_Margin,
		ROUND(100 * (Total_Revenue - LAG(Total_Revenue) OVER(ORDER BY Start_of_Month)) / NULLIF(LAG(Total_Revenue) OVER(ORDER BY Start_of_Month), 0), 2) AS Revenue_MoM,
		ROUND(100 * (Total_Profit - LAG(Total_Profit) OVER(ORDER BY Start_of_Month)) / NULLIF(LAG(Total_Profit) OVER(ORDER BY Start_of_Month), 0), 2) AS Profit_MoM,
		ROUND(100 * (Total_Orders - LAG(Total_Orders) OVER (ORDER BY Start_of_Month)) / NULLIF(LAG(Total_Orders) OVER(ORDER BY Start_of_Month), 0), 2) AS Orders_MoM,
		ROUND(100 * (Total_Revenue - LAG(Total_Revenue, 12) OVER(ORDER BY Start_of_Month)) / NULLIF(LAG(Total_Revenue, 12) OVER(ORDER BY Start_of_Month), 0), 2) AS Revenue_YoY,
		ROUND(100 * (Total_Profit - LAG(Total_Profit, 12) OVER(ORDER BY Start_of_Month)) / NULLIF(LAG(Total_Profit, 12) OVER(ORDER BY Start_of_Month), 0), 2) AS Profit_YoY
	FROM CTE_monthly_growth
) AS t
ORDER BY Start_of_Month;