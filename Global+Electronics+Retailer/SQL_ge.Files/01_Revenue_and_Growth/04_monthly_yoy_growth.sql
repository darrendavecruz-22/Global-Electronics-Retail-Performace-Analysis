-- Month-over-Month MoM

/*
Questions:
Q1: Which months experienced simultaneous declines in revenue and gross profit?
Q2: Which months experienced the largest revenue declines?
Q3: Which months experienced the largest profit declines?
Q4: Do revenue and profit declines coincide with lower order volume?
Q5: Are declines concentrated in particular months or repeated across multiple years?
*/

-- Sol'n: Calculate the MoM for total revenue, total profit, and total orders.
-- Compare the revenue and profit for each month from previous year.
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