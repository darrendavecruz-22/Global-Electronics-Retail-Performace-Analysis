-- Year-over-Year (YoY)

/*
Questions:
Q1: How has annual revenue changed from one year to the next?
Q2: Is gross profit growing faster or slower than revenue?
Q3: Has the retailer's profit margin improved or deteriorated over time?
Q4: Are increases in revenue accompanied by increases in order volume?
Q5: Which complete year had the strongest and weakest revenue growth?
Q6: Which complete year had the strongest and weakest profit growth?
*/

-- Sol'n: Summarize the total revenue, total profit, total cost, total orders by year
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