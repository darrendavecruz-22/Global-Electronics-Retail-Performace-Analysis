/* =============================================================================
   View: ge.vw_sales_products_fact

   Purpose: Main basis for the Global Electronics Retail analysis.
   Combines each sales line item with its product details and
   calculates revenue, cost, and profit per line.

   Source: ge.Sales and ge.Products

   Notes: Combines each row in ge.Sales to its product in ge.Products using
   LEFT JOIN on ProductKey, then adds Revenue, Variable_Cost, and 
   Gross_Profit for every line item.
================================================================================ */

CREATE OR ALTER VIEW ge.vw_sales_products_fact AS
(
SELECT
	p.Product_Name, p.Brand, p.Category, p.Subcategory,
    p.Unit_Cost_USD, p.Unit_Price_USD,
	s.Order_Number, s.Line_Item, s.Order_Date, s.Delivery_Date,
    s.CustomerKey, s.StoreKey, s.ProductKey, s.Quantity, s.Currency_Code,
	p.Unit_Price_USD * s.Quantity AS Revenue,
	p.Unit_Cost_USD * s.Quantity AS Variable_Cost,
	s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD) AS Gross_Profit
FROM ge.Sales AS s
LEFT JOIN ge.Products AS p
ON s.ProductKey = p.ProductKey
)
GO