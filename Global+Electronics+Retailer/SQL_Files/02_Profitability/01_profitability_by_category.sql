/* -----------------------------------------------------------------------------
   Query: Category summary
   Purpose: Compares product categories on size, profitability, and share of 
   the business

   Notes: Groups the sales fact view by category for 2016 to 2020 and
   calculates totals, margin, shares, and rankings. Shares use a
   window function over all categories, so each column adds up to
   100. Results are sorted from the highest to the lowest profit.
   ----------------------------------------------------------------------------- */

-- Check the totals. It must match your earlier results.
SELECT
	SUM(Revenue) AS Total_Revenue,
	SUM(Gross_Profit) AS Total_Profit,
	COUNT(DISTINCT Category) AS Categories,
	COUNT(DISTINCT Subcategory) AS Subcategories
FROM ge.vw_sales_products_fact
WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020;
-- 8 Categories & 32 Subcategories

-- Main Query
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
	CAST(ROUND(1.0 * SUM(Gross_Profit) / SUM(Quantity), 2) AS DECIMAL(18,2)) AS Profit_per_unit,
	CAST(ROUND(1.0 * SUM(Revenue) / SUM(Quantity), 2) AS DECIMAL(18,2)) AS Avg_selling_price
FROM ge.vw_sales_products_fact
WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
GROUP BY Category
ORDER BY CAST(ROUND(SUM(Gross_Profit), 2) AS DECIMAL(18,2)) DESC;