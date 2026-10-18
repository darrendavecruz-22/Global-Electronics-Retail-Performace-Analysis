-- 03_profitability_by_brand

/*
Questions:
Q1: Which brands generate the most revenue and gross profit, and does profit share match revenue share?
Q2: Which brands earn the highest and lowest margin and profit per unit?
Q3: How dependent is each brand on a single category?
Q4: Which brands are growing or shrinking year over year?
*/

-- Check the number of brands
SELECT
	COUNT(DISTINCT Brand) AS Total_Brands,
	SUM(Total_Revenue) AS Revenue,
	SUM(Total_Profit) AS Profit
FROM ge.vw_product_profitability
-- There should be a total of 11 brands.

-- Sol'n Q1 and Q2: Brand Summary
SELECT
	Brand,

	-- Product sold, Sum of revenue, units sold, and profit, and profit margin.
	COUNT(*) AS Product_Sold,
	SUM(Units_Sold) AS Total_Units,
	SUM(Total_Revenue) AS Revenue,
	SUM(Total_Profit) AS Profit,
	CAST(ROUND(100.0 * SUM(Total_Profit) / SUM(Total_Revenue), 2) AS DECIMAL(18,2)) AS Profit_Margin,

	-- Profit per unit and Average selling price.
	CAST(ROUND(1.0 * SUM(Total_Profit) / SUM(Units_Sold), 2) AS DECIMAL(18,2)) AS Profit_per_Unit,
	CAST(ROUND(1.0 * SUM(Total_Revenue) / SUM(Units_Sold), 2) AS DECIMAL(18,2)) AS Avg_selling_Price,
	
	-- Profit share, Revenue share, and Share gap
	CAST(ROUND(100.0 * SUM(Total_Revenue) / SUM(SUM(Total_Revenue)) OVER(), 2) AS DECIMAL(18,2)) AS Revenue_Share,
	CAST(ROUND(100.0 * SUM(Total_Profit) / SUM(SUM(Total_Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_Share,
	CAST(ROUND(
				100.0 * SUM(Total_Revenue) / SUM(SUM(Total_Revenue)) OVER() - 100.0 * SUM(Total_Profit) / SUM(SUM(Total_Profit)) OVER(), 2)
		AS DECIMAL(18,2)) AS Share_Gap,

	-- Profit_Rank and Margin_Rank
	RANK() OVER(ORDER BY SUM(Total_Profit) DESC) AS Profit_rank,
	RANK() OVER(ORDER BY SUM(Total_Profit) / SUM(Total_Revenue) DESC) AS Margin_rank

FROM ge.vw_product_profitability
GROUP BY Brand
ORDER BY Profit DESC;

-- Sol'n Q3: Category dependence per brand
WITH CTE_brand_category AS
(
	SELECT
		Brand, Category,
		SUM(Total_Revenue) AS Revenue,
		SUM(Total_Profit)  AS Profit
	FROM ge.vw_product_profitability
	GROUP BY Brand, Category
),

CTE_share AS
(
	SELECT
		*,
		CAST(ROUND(100.0 * Profit / SUM(Profit) OVER(PARTITION BY Brand), 2) AS DECIMAL(18,2)) AS Brand_Share,
		RANK() OVER(PARTITION BY Brand ORDER BY Profit DESC) AS Brand_rank,
		COUNT(*) OVER(PARTITION BY Brand) AS Categories_Sold
	FROM CTE_brand_category
)

-- Main Query
SELECT
	Brand, Categories_Sold,

	-- Top Brand per Category and Share
	MAX(CASE WHEN Brand_rank = 1 THEN Category END) AS Top_Category,
	MAX(CASE WHEN Brand_rank = 1 THEN Brand_Share END) AS Top_Share,

	-- Second place
	MAX(CASE WHEN Brand_rank = 2 THEN Category END) AS Second_Category,
	MAX(CASE WHEN Brand_rank = 2 THEN Brand_Share END) AS Second_Share

FROM CTE_share
WHERE Categories_Sold != 1
GROUP BY Brand, Categories_Sold
ORDER BY Top_Share DESC;

-- Sol'n Q4: Brand growth, year over year
WITH CTE_yearly AS
(
	SELECT
		YEAR(Order_Date) AS Year,
		Brand,
		SUM(Revenue) AS Revenue,
		SUM(Gross_Profit) AS Profit
	FROM ge.vw_sales_products_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY YEAR(Order_Date), Brand
),
CTE_calc AS
(
	SELECT
		*,
		LAG(Revenue) OVER(PARTITION BY Brand ORDER BY Year) AS Prev_Revenue,
		LAG(Profit) OVER(PARTITION BY Brand ORDER BY Year) AS Prev_Profit,
		CAST(ROUND(100.0 * Profit / SUM(Profit) OVER(PARTITION BY Year), 2) AS DECIMAL(18,2)) AS Share_of_Year_Profit
	FROM CTE_yearly
)
SELECT
	Year, Brand, Revenue, Profit,

	-- Revenue YoY and Profit YoY
	CAST(ROUND(100.0 * (Revenue - Prev_Revenue) / NULLIF(Prev_Revenue, 0), 2) AS DECIMAL(18,2)) AS Revenue_YoY,
	CAST(ROUND(100.0 * (Profit - Prev_Profit) / NULLIF(Prev_Profit, 0), 2) AS DECIMAL(18,2)) AS Profit_YoY,

	-- Shares, Shares Difference per year
	Share_of_Year_Profit,
	ROUND(Share_of_Year_Profit
	      - LAG(Share_of_Year_Profit) OVER(PARTITION BY Brand ORDER BY Year), 2)    AS Share_Change
FROM CTE_calc
WHERE Prev_Revenue IS NOT NULL
ORDER BY Year, Profit DESC;