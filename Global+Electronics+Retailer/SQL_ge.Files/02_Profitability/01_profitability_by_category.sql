-- 01_profitability_by_category

/*
Questions:
Q1: Which categories generate the most revenue and gross profit?
Q2: Which categories earn the highest and lowest margin?
Q3: Does a category's share of profit match its share of revenue?
Q4: Which subcategories are the strongest and weakest within each category?
Q5: Which categories earn the most profit per unit sold?
*/

-- Check the totals. It must match your earlier results.
SELECT
	SUM(Revenue) AS Total_Revenue,
	SUM(Gross_Profit) AS Total_Profit,
	COUNT(DISTINCT Category) AS Categories,
	COUNT(DISTINCT Subcategory) AS Subcategories
FROM ge.vw_sales_products_fact
WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020;
-- 8 Categories & 32 Subcategories

-- Sol'n Q1, Q2, Q3, Q5: Category Summary
SELECT
	-- Total revenue, profit, margin
	Category,
	CAST(ROUND(SUM(Revenue), 2) AS DECIMAL(18,2)) AS Total_Revenue,
	CAST(ROUND(SUM(Gross_Profit), 2) AS DECIMAL(18,2)) AS Total_Profit,
	CAST(ROUND(100.0 * SUM(Gross_Profit) / SUM(Revenue), 2) AS DECIMAL(18,2)) AS Profit_Margin,

	-- Revenue share, profit share, and share gap
	CAST(ROUND(100.0 * SUM(Revenue) / SUM(SUM(Revenue)) OVER (), 2) AS DECIMAL(18,2)) AS Revenue_Share,
	CAST(ROUND(100.0 * SUM(Gross_Profit) / SUM(SUM(Gross_Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_Share,
	CAST(ROUND(100.0 * SUM(Gross_Profit) / SUM(SUM(Gross_Profit)) OVER(), 2) AS DECIMAL(18,2)) -
	CAST(ROUND(100.0 * SUM(Revenue) / SUM(SUM(Revenue)) OVER (), 2) AS DECIMAL(18,2)) AS Share_Gap,

	-- Ranking (Revenue, profit, margin)
	RANK() OVER(ORDER BY CAST(ROUND(SUM(Revenue), 2) AS DECIMAL(18,2)) DESC) AS Revenue_ranking,
	RANK() OVER(ORDER BY CAST(ROUND(SUM(Gross_Profit), 2) AS DECIMAL(18,2)) DESC) AS Profit_ranking,
	RANK() OVER(ORDER BY CAST(ROUND(100.0 * SUM(Gross_Profit) / SUM(Revenue), 2) AS DECIMAL(18,2)) DESC) AS Margin_ranking,

	-- Unit sold, profit per unit, Average selling price
	SUM(Quantity) AS Units_Sold,
	CAST(ROUND(100.0 * SUM(Gross_Profit) / SUM(Quantity), 2) AS DECIMAL(18,2)) AS Profit_per_unit,
	CAST(ROUND(100.0 * SUM(Revenue) / SUM(Quantity), 2) AS DECIMAL(18,2)) AS Avg_selling_price
FROM ge.vw_sales_products_fact
WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
GROUP BY Category
ORDER BY CAST(ROUND(SUM(Gross_Profit), 2) AS DECIMAL(18,2)) DESC;

-- Sol'n Q4: Subcategory summary, ranked within each category
WITH CTE_subcategory AS
(
	SELECT
		Category, Subcategory,
		SUM(Revenue) AS Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		SUM(Quantity) AS Units_Sold
	FROM ge.vw_sales_products_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY Category, Subcategory
)

SELECT
	Category, Subcategory,

	-- Total revenue, profit, margin
	CAST(ROUND(Total_Revenue, 2) AS DECIMAL(18,2)) AS Total_Revenue,
	CAST(ROUND(Total_Profit, 2) AS DECIMAL(18,2)) AS Total_Profit,
	CAST(ROUND(100.0 * Total_Profit / Total_Revenue, 2) AS DECIMAL(18,2)) AS Profit_Margin,
	
	-- Share of Category and total share
	CAST(ROUND(100.0 * Total_Profit / SUM(Total_Profit) OVER(PARTITION BY Category), 2) AS DECIMAL(18,2)) AS Category_Share,
	CAST(ROUND(100.0 * Total_Profit / SUM(Total_Profit) OVER(), 2) AS DECIMAL(18,2)) AS Total_Share,

	-- Profit rank by category and profit rank
	RANK() OVER(PARTITION BY Category ORDER BY Total_Profit DESC) AS Category_profit_ranking,
	RANK() OVER(ORDER BY Total_Profit DESC) AS Profit_ranking,

	-- Profit per units
	CAST(ROUND(100.0 * Total_Profit / Units_Sold, 2) AS DECIMAL(18,2)) AS Profit_per_unit

FROM CTE_subcategory
ORDER BY Category, Category_profit_ranking;

-- Additional: Find the Top 10 and Bottom 10 subcategories in terms of profit.
WITH CTE_subcategory AS
(
	SELECT
		Category, Subcategory,
		SUM(Revenue) AS Total_Revenue, SUM(Gross_Profit) AS Total_Profit
	FROM ge.vw_sales_products_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY Category, Subcategory
),
CTE_rank AS
(
	SELECT *,
		RANK() OVER(ORDER BY Total_Profit DESC) AS Top_Rank,
		RANK() OVER(ORDER BY Total_Profit ASC)  AS Bottom_Rank
	FROM CTE_subcategory
)
SELECT
	CASE WHEN Top_Rank <= 10 THEN 'Top 10' ELSE 'Bottom 10' END AS Group_Label,
	Category, Subcategory,
	ROUND(Total_Revenue, 2) AS Revenue,
	ROUND(Total_Profit, 2) AS Gross_Profit,
	CAST(ROUND(100.0 * Total_Profit / Total_Revenue, 2) AS DECIMAL(18,2)) AS Profit_Margin
FROM CTE_rank
WHERE Top_Rank <= 10 OR Bottom_Rank <= 10
ORDER BY Group_Label DESC, Gross_Profit DESC;