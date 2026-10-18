-- 02_profitability_by_product

/*
Questions:
Q1: Which products generate the most gross profit?
Q2: Which products generate the least gross profit among those that sold?
Q3: Which products earn the most profit per unit sold?
Q4: Which are the top products within each category?
*/

-- Check: the view must match the fact view totals, and shows how many products never sold
SELECT
	COUNT(*) AS Products_w_sales,
	(SELECT COUNT(*) FROM ge.Products) AS Products_in_catalog,
	SUM(Total_Revenue) AS Revenue,
	SUM(Total_Profit) AS Profit
FROM ge.vw_product_profitability;
-- If Product_w_sales < Products_in_catalog then some products weren't sold.

-- Sol'n Q1 and Q2: Top 10 and bottom 10 products by gross profit
WITH CTE_ranking AS
(
	SELECT *,
		RANK() OVER(ORDER BY Total_Profit DESC) AS Top_Rank,
		RANK() OVER(ORDER BY Total_Profit ASC)  AS Bottom_Rank
	FROM ge.vw_product_profitability
)

SELECT
	-- Top 10 and Bottom 10
	CASE WHEN Top_Rank <= 10 THEN 'Top 10' ELSE 'Bottom_10' END AS Group_label,

	ProductKey, Product_Name, Brand, Category, Units_Sold, Total_Revenue, Total_Profit,

	-- Gross margin
	CAST(ROUND(100.0 * Total_Profit / Total_Revenue, 2) AS DECIMAL(18,2)) AS Profit_Margin,

	-- Profit Share
	CAST(ROUND(100.0 * Total_Profit / SUM(Total_Profit) OVER(), 2) AS DECIMAL(18,2)) AS Profit_share

FROM CTE_ranking
WHERE Top_Rank <= 10 OR Bottom_Rank <= 10
ORDER BY Group_label DESC, Total_Profit DESC;

-- Sol'n Q3: Most profit per unit.
SELECT TOP 15
	ProductKey, Product_Name, Brand, Category, Units_Sold, Total_Revenue, Total_Profit,
	CAST(ROUND(1.0 * Total_Profit / Units_Sold , 2) AS DECIMAL(18,2)) AS Profit_per_unit,
	CAST(ROUND(100.0 * Total_Profit / Total_Revenue, 2) AS DECIMAL(18,2)) AS Profit_Margin
FROM ge.vw_product_profitability
WHERE Units_Sold >= 50
ORDER BY Profit_per_unit DESC;

-- Sol'n Q4: Top 3 products within each category
WITH CTE_category_ranking AS
(
	SELECT
		ProductKey, Product_Name, Brand, Category, Units_Sold, Total_Revenue, Total_Profit,
		RANK() OVER(PARTITION BY Category ORDER BY Total_Profit DESC) AS Category_profit_ranking,
		CAST(ROUND(100.0 * Total_Profit / SUM(Total_Profit) OVER(PARTITION BY Category), 2) AS DECIMAL(18, 2)) AS Profit_share
	FROM ge.vw_product_profitability
)

SELECT
	Category, ProductKey, Product_Name, Brand, Units_Sold, Total_Revenue, Total_Profit,
	CAST(ROUND(100.0 * Total_Profit / Total_Revenue, 2) AS DECIMAL(18,2)) AS Profit_Margin,
	Profit_share
FROM CTE_category_ranking
WHERE Category_profit_ranking <= 3
ORDER BY Category, Category_profit_ranking;