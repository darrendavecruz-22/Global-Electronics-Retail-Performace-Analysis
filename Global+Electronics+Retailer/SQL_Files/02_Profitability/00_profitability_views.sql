/* -----------------------------------------------------------------------------
   View: ge.vw_product_profitability
   Purpose: Total revenue, profit, and units sold for each product.

   Notes: Goups the sales fact view by product and totals revenue, gross
   profit, and quantity. Only orders from 2016 to 2020 are
   included, so the totals cover complete years. Products with no
   sales in that period do not appear.
   ----------------------------------------------------------------------------- */
CREATE OR ALTER VIEW ge.vw_product_profitability AS

	SELECT
		ProductKey, Product_Name, Brand, Category, Subcategory,
		SUM(Revenue) AS Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		SUM(Quantity) AS Units_Sold
	FROM ge.vw_sales_products_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY ProductKey, Product_Name, Brand, Category, Subcategory

GO

/* -----------------------------------------------------------------------------
   View: ge.vw_sales_products_countries_fact
   Purpose: Sales fact view with the customer's country and continent
   added, for analysis by customer location.

   Notes: Keeps all columns from the sales fact view and adds the
   customer's country and continent.
   ----------------------------------------------------------------------------- */
CREATE OR ALTER VIEW ge.vw_sales_products_countries_fact AS

	SELECT
		sp.*,
		c.Country AS Customer_Country, c. Continent AS Customer_Continent
	FROM ge.vw_sales_products_fact AS sp
	LEFT JOIN ge.Customers AS c
	ON sp.CustomerKey = c.CustomerKey

GO