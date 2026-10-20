/* -----------------------------------------------------------------------------
   Query: Top 10 and bottom 10 products by gross profit
   Purpose: Shows the products that earn the most and the least profit.

   Notes: Ranks all products by total profit in both directions and keeps
   the 10 highest and 10 lowest. Profit_share is calculated before
   the top and bottom products are selected, so it is a share of
   the whole business, not of these 20 products.
   ----------------------------------------------------------------------------- */
-- Check: the view must match the fact view totals, and shows how many products never sold
SELECT
	COUNT(*) AS Products_w_sales,
	(SELECT COUNT(*) FROM ge.Products) AS Products_in_catalog,
	SUM(Total_Revenue) AS Revenue,
	SUM(Total_Profit) AS Profit
FROM ge.vw_product_profitability;
-- If Product_w_sales < Products_in_catalog then some products weren't sold.

-- Top 10 and bottom 10 products by gross profit
WITH CTE_ranking AS
(
	SELECT *,
		RANK() OVER(ORDER BY Total_Profit DESC) AS Top_Rank,
		RANK() OVER(ORDER BY Total_Profit ASC)  AS Bottom_Rank
	FROM ge.vw_product_profitability
)

-- Main query
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