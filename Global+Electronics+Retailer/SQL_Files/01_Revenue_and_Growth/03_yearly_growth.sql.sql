/* =============================================================================
   Query: Year-Over-Year Growth (YoY)

   Purpose: Gives a general overview of year-over-year (YoY) performance:
   yearly totals, profit margin, and YoY growth in revenue,
   profit, and orders.

   Notes: Totals the sales fact view by year, then compares each year with
   the one before it using LAG. Only years with 12 months of data
   are kept, so a partial year cannot distort the growth rates.
   ============================================================================= */

WITH CTE_yearly_growth AS
(
	SELECT
		YEAR(Order_Date) AS Year,
		SUM(Revenue) AS Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		SUM(Quantity) AS Total_Cost,
		COUNT(DISTINCT Order_Number) AS Total_Orders,
		COUNT(DISTINCT DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1)) AS Total_Months
	FROM ge.vw_sales_products_fact
	GROUP BY YEAR(Order_Date)
)

-- Main Query
SELECT
	Year,
	Total_Months,
	Total_Orders,
	Total_Cost,
	Total_Revenue,
	Total_Profit,
	ROUND((Total_Profit/Total_Revenue) * 100, 2) AS Profit_Margin,
	ROUND(100 * (Total_Revenue - LAG(Total_Revenue) OVER(ORDER BY Year)) / NULLIF(LAG(Total_Revenue) OVER(ORDER BY Year), 0), 2) AS Revenue_YoY,
	ROUND(100 * (Total_Profit - LAG(Total_Profit) OVER(ORDER BY Year)) / NULLIF(LAG(Total_Profit) OVER(ORDER BY Year), 0), 2) AS Profit_YoY,
	ROUND(100* (Total_Orders - LAG(Total_Orders) OVER(ORDER BY Year)) / NULLIF(LAG(Total_Orders) OVER(ORDER BY Year), 0), 2) AS Orders_YoY
FROM CTE_yearly_growth
WHERE Total_Months = 12
ORDER BY Year;