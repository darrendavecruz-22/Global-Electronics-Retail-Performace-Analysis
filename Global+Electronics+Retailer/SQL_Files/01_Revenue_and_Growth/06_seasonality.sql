/* =============================================================================
   Query: Monthly Seasonality

   Purpose: Ranks the 12 calendar months by how far they sit above or below
   a normal month.

   Notes: Each month is first compared with the average month of its own
   year, which removes the effect of overall business growth. The
   indexes are then averaged by calendar month to show the
   seasonal pattern. Only 2016 to 2020 are included, so years
   with partial data do not distort the averages.
   ============================================================================= */

-- Setup: shared monthly view
CREATE OR ALTER VIEW ge.vw_monthly_summary AS
(	
	SELECT
		YEAR(Order_Date) AS Year,
		DATEPART(quarter, Order_Date) AS Quarter,
		MONTH(Order_Date) AS Month,
		SUM(Revenue) AS Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		SUM(Quantity) AS Total_Units,
		COUNT(DISTINCT Order_Number) AS Total_Orders
	FROM ge.vw_sales_products_fact
	GROUP BY YEAR(Order_Date), DATEPART(quarter, Order_Date), MONTH(Order_Date)
)
GO


WITH CTE_index AS
(
	SELECT
		*,
		CAST(ROUND(1.0 * Total_Revenue / AVG(Total_Revenue) OVER(PARTITION BY Year), 2) AS DECIMAL(18,2)) AS Revenue_Index,
		CAST(ROUND(1.0 * Total_Profit / AVG(Total_Profit) OVER(PARTITION BY Year), 2) AS DECIMAL(18,2)) AS Profit_Index,
		CAST(ROUND(1.0 * Total_Orders / AVG(1.0 * Total_Orders) OVER(PARTITION BY Year), 2) AS DECIMAL(18,2)) AS Orders_Index,
		CAST(ROUND((Total_Revenue / Total_Orders) / 
		(SUM(Total_Revenue) OVER(PARTITION BY Year) / SUM(Total_Orders) OVER(PARTITION BY Year)), 2) AS DECIMAL(18,2)) AS AOV_Index
	FROM ge.vw_monthly_summary
	WHERE Year BETWEEN 2016 AND 2020
)

SELECT
	Month,
	DATENAME(month, DATEFROMPARTS(2000, Month, 1)) AS Month_name,
	ROUND(AVG(Total_Revenue), 2) AS Avg_Revenue,
	ROUND(AVG(Total_Profit), 2) AS Avg_Profit,
	CAST(ROUND(AVG(Revenue_Index), 2) AS DECIMAL(5,2)) AS Avg_Revenue_Index,
	SUM(CASE WHEN Revenue_Index > 1 THEN 1 ELSE 0 END) AS Years_Above_Average,
	RANK() OVER(ORDER BY AVG(Revenue_Index) DESC) AS Ranking,
	CAST(ROUND(AVG(Profit_Index), 2) AS DECIMAL(18,2)) AS Avg_Profit_Index,
	CAST(ROUND(100.0 * SUM(Total_Profit) / SUM(Total_Revenue), 2) AS DECIMAL(18,2)) AS Profit_Margin,
	CAST(ROUND(AVG(Orders_Index), 2) AS DECIMAL(18,2)) AS Avg_Orders_Index,
	CAST(ROUND(AVG(AOV_Index), 2) AS DECIMAL(18,2)) AS Avg_AOV_Index
FROM CTE_index
GROUP BY Month
ORDER BY Month;