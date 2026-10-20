/* =============================================================================
   Query: Baseline Key Performance Indicators (KPIs)

   Purpose: Provides an overview on revenue, profit, margin, units sold,
   and order value.

   Notes: Groups the sales and products fact view and calculates the main
   KPIs for each one.
   ============================================================================= */
SELECT
	SUM(Revenue) As Total_Revenue,
	SUM(Gross_Profit) AS Total_Profit,
	ROUND(SUM(Gross_Profit)/SUM(Revenue) * 100, 2) AS Profit_Margin,
	SUM(Quantity) AS Units_Sold,
	COUNT(DISTINCT Order_Number) AS Total_Orders,
	ROUND(SUM(Revenue)/COUNT(DISTINCT Order_Number), 2) AS Avg_Order_Value
FROM ge.vw_sales_products_fact
ORDER BY Total_Profit DESC;