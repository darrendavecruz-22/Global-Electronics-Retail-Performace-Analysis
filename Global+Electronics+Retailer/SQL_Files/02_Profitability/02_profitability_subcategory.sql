/* -----------------------------------------------------------------------------
   Query: Subcategory performance summary
   Purpose: Compares product subcategories on revenue, profit, margin, and
   share of profit, to show which subcategories drive each
   category and the business as a whole.

   Notes: Totals the sales fact view by subcategory for 2016 to 2020,
   then uses window functions to calculate profit shares and
   rankings. Results are sorted by category, then by profit rank within 
   the category.
   ----------------------------------------------------------------------------- */

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

-- Main query
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