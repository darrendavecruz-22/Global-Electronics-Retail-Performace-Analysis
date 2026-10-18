-- Seasonality

/* 
Questions:
Q1: Which months consistently generate the most revenue?
Q2: Which months have the highest average monthly revenue?
Q3: Does the business consistently perform better in certain quarters?
Q4: Which product categories have different seasonal sales patterns?
Q5: Are seasonal revenue peaks also the most profitable periods?
Q6: Are sales peaks driven by more orders or larger purchases?
Q7: Can historical seasonal patterns help establish next year's sales targets?
*/

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

-- Q1, Q2, Q6, Q7: Monthly seasonality index
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
	CASE
		WHEN CAST(ROUND(AVG(Revenue_Index), 2) AS DECIMAL(5,2)) > 1 AND CAST(ROUND(AVG(Profit_Index), 2) AS DECIMAL(18,2)) < 1 THEN 'High Revenue, Low Profit'
		WHEN CAST(ROUND(AVG(Revenue_Index), 2) AS DECIMAL(5,2)) < 1 AND CAST(ROUND(AVG(Profit_Index), 2) AS DECIMAL(18,2)) > 1 THEN 'Low Revenue, High Profit'
		ELSE 'Aligned'
	END AS Flag_Revenue_Profit,
	CAST(ROUND(AVG(Orders_Index), 2) AS DECIMAL(18,2)) AS Avg_Orders_Index,
	CAST(ROUND(AVG(AOV_Index), 2) AS DECIMAL(18,2)) AS Avg_AOV_Index,
	CASE
		WHEN CAST(ROUND(AVG(Revenue_Index), 2) AS DECIMAL(5,2)) <= 1 THEN 'Not high-sales month'
		WHEN CAST(ROUND(AVG(Orders_Index), 2) AS DECIMAL(5,2)) > 1.02 AND CAST(ROUND(AVG(AOV_Index), 2) AS DECIMAL(5,2)) > 1.02 THEN 'Both'
		WHEN CAST(ROUND(AVG(Orders_Index), 2) AS DECIMAL(5,2)) > 1.02 THEN 'High Orders'
		WHEN CAST(ROUND(AVG(AOV_Index), 2) AS DECIMAL(5,2)) > 1.02 THEN 'Larger Purchases'
		ELSE 'Neither'
	END AS Orders_vs_Purchases
FROM CTE_index
GROUP BY Month
ORDER BY Month;

-- Q3: Quarterly share of annual revenue
WITH CTE_quarters AS
(
	SELECT
		Year, Quarter,
		SUM(Total_Revenue) AS Revenue,
		CAST(ROUND(100.0 * SUM(Total_Revenue) / SUM(SUM(Total_Revenue)) OVER(PARTITION BY Year), 2) AS DECIMAL(18,2)) AS Share_of_year
	FROM ge.vw_monthly_summary
	WHERE Year BETWEEN 2016 AND 2020
	GROUP BY Year, Quarter
),

CTE_rank AS
(
	SELECT
		*,
		RANK() OVER(PARTITION BY Year ORDER BY Share_of_Year) AS Ranking_of_Shares
	FROM CTE_quarters
)

SELECT
	Quarter,
	CAST(ROUND(AVG(Share_of_Year), 2) AS DECIMAL(18,2)) AS Avg_Share,
	MIN(Share_of_Year) AS Lowest_Share,
	MAX(Share_of_Year) AS Highest_Share,
	SUM(CASE WHEN Ranking_of_Shares = 1 THEN 1 ELSE 0 END) AS Year_Best_Quarter
FROM CTE_rank
GROUP BY Quarter
ORDER BY Quarter;

-- Q4: Category seasonality
WITH CTE_category AS
(
	SELECT
		Category,
		YEAR(Order_Date) AS Year,
		MONTH(Order_Date) AS Month,
		SUM(Revenue) AS Total_Revenue
	FROM ge.vw_sales_products_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY Category, YEAR(Order_Date), MONTH(Order_Date)
), 

CTE_index AS
(
	SELECT 
		*, 
		1.0 * Total_Revenue / AVG(Total_Revenue) OVER(PARTITION BY Year) AS Revenue_Index
	FROM CTE_category
),

CTE_average AS
(
	SELECT
		Category,
		Month,
		CAST(ROUND(AVG(Revenue_Index), 2) AS DECIMAL(18, 2)) AS Seasonality_Index
	FROM CTE_index
	GROUP BY Category, Month
)

-- Main Query
SELECT 
	Category,
	Month,
	Seasonality_Index,
	CASE 
		WHEN Seasonality_Index >= 1 THEN 'Above_Average' 
		WHEN Seasonality_Index < 1 THEN 'Below Average' 
	END AS Performance,
	MAX(Seasonality_Index) OVER(PARTITION BY Category) - MIN(Seasonality_Index) OVER(PARTITION BY Category) AS Seasonal_Range
FROM CTE_average
ORDER BY Category, Month;

-- Q7: Monthly phasing for targets
WITH CTE_shares AS
(
	SELECT
		Year, Month,
		CAST(ROUND(100.0 * Total_Revenue / SUM(Total_Revenue) OVER(PARTITION BY Year), 2) AS DECIMAL(18,2)) AS Share_of_Year
	FROM ge.vw_monthly_summary
	WHERE Year BETWEEN 2016 AND 2020
)

-- Main Query
SELECT
	Month,
	CAST(ROUND(AVG(Share_of_Year), 2) AS DECIMAL(18,2)) AS Avg_Share,
	MIN(Share_of_Year) AS Lowest_Share,
	MAX(Share_of_Year) AS Highest_Share,
	MAX(Share_of_Year) - MIN(Share_of_Year) AS Share_Range,
	CEILING(CAST(10000000 * AVG(Share_of_Year) / 100 AS DECIMAL(18,2))) AS Target_at_10M_Annual
FROM CTE_shares
GROUP BY Month
ORDER BY Month;