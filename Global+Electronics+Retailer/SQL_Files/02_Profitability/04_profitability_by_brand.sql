/* -----------------------------------------------------------------------------
   Query: Brand summary
   Purpose: Compares brands on size, profitability, share of the business,
   and unit economics.

   Notes: Totals the product profitability view by brand and calculates
   margin, unit values, shares, and rankings. Results are sorted from 
   the highest to the lowest profit.
   ----------------------------------------------------------------------------- */

-- Check the number of brands
SELECT
	COUNT(DISTINCT Brand) AS Total_Brands,
	SUM(Total_Revenue) AS Revenue,
	SUM(Total_Profit) AS Profit
FROM ge.vw_product_profitability
-- There should be a total of 11 brands.

-- Main query
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