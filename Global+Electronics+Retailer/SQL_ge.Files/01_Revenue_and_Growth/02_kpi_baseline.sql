-- Baseline Key Performance Indicators (KPIs)

/* 
Questions:
Q1: How much revenue and gross profit did the retailer generate?
Q2: What percentage of revenue is retained as gross profit?
Q3: How many units were sold and how many orders were placed?
Q4: What is the average revenue generated per order?
Q5: Which product or channel segments should be investigated for profitability?
*/

-- Sol'n: Calculate the total revenue, total profit, profit margin, unit sold, total orders, average order value.
-- Compare it across Category.
SELECT
	*
FROM 
(
	SELECT
		Category,
		SUM(Revenue) As Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		ROUND(SUM(Gross_Profit)/SUM(Revenue) * 100, 2) AS Profit_Margin,
		SUM(Quantity) AS Units_Sold,
		COUNT(DISTINCT Order_Number) AS Total_Orders,
		ROUND(SUM(Revenue)/COUNT(DISTINCT Order_Number), 2) AS Avg_Order_Value
	FROM ge.vw_sales_products_fact
	GROUP BY Category
) AS t
ORDER BY Total_Profit DESC;