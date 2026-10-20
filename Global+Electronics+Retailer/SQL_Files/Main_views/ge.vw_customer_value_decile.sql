/* =============================================================================
   View: ge.vw_customer_value_decile
   Purpose: Ranks customers by lifetime gross profit and places each one
   in a value decile (1 = top 10% most profitable customers, 10 = bottom 10%).

   Notes: Adds up each customer's gross profit across all of their
   orders, then ranks customers from highest to lowest profit and
   splits them into ten equal-sized groups using NTILE(10).
   ============================================================================= */
CREATE OR ALTER VIEW ge.vw_customer_value_decile AS
SELECT
    CustomerKey,
    SUM(Gross_Profit) AS Lifetime_Gross_Profit,
    NTILE(10) OVER (ORDER BY SUM(Gross_Profit) DESC, CustomerKey) AS Value_Decile
FROM ge.vw_sales_products_fact
GROUP BY CustomerKey
GO