-- 05_margin_trend_analysis

/*
Questions:
Q1: Is the overall profit margin stable from year to year?
Q2: Is margin stable within each category, or does any category drift?
*/

WITH CTE_year AS
(
	SELECT
		YEAR(Order_Date) AS Year, SUM(Revenue) AS Revenue, SUM(Gross_Profit) AS Profit
	FROM ge.vw_sales_products_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY YEAR(Order_Date)
)

SELECT
	Year, Revenue, Profit,
	CAST(ROUND(100.0 * Profit / Revenue, 2) AS DECIMAL(18, 2)) AS Profit_Margin,
	CAST(ROUND(100.0 * Profit / Revenue
	    - LAG(100.0 * Profit / Revenue) OVER(ORDER BY Year), 2) AS DECIMAL(18,2)) AS Margin_Change
FROM CTE_year
ORDER BY Year;

-- Sol'n Q2: Margin by category and year (Pivot)
WITH CTE_category_year AS
(
	SELECT
		Category,
		YEAR(Order_Date) AS Year,
		SUM(Revenue) AS Revenue,
		SUM(Gross_Profit) AS Profit
	FROM ge.vw_sales_products_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY Category, YEAR(Order_Date)
),

CTE_margin AS
( 
	SELECT 
		Year, Category, Revenue, Profit,
		CAST(ROUND(100.0 * Profit / Revenue, 2) AS DECIMAL(18, 2)) AS Profit_margin
	FROM CTE_category_year
)

SELECT
	Category,
	CAST(ROUND(MAX(CASE WHEN Year = '2016' THEN Profit_margin END), 2) AS DECIMAL(18,2)) AS [2016],
	CAST(ROUND(MAX(CASE WHEN Year = '2017' THEN Profit_margin END), 2) AS DECIMAL(18,2)) AS [2017],
	CAST(ROUND(MAX(CASE WHEN Year = '2018' THEN Profit_margin END), 2) AS DECIMAL(18,2)) AS [2018],
	CAST(ROUND(MAX(CASE WHEN Year = '2019' THEN Profit_margin END), 2) AS DECIMAL(18,2)) AS [2019],
	CAST(ROUND(MAX(CASE WHEN Year = '2020' THEN Profit_margin END), 2) AS DECIMAL(18,2)) AS [2020],
	CAST(ROUND(MAX(Profit_margin) - MIN(Profit_margin), 2) AS DECIMAL(18, 2)) AS Margin_Range
FROM CTE_margin
GROUP BY Category
ORDER BY Margin_Range DESC;