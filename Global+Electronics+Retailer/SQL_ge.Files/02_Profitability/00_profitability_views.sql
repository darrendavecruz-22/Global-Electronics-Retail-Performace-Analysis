-- Views

-- Products
CREATE OR ALTER VIEW ge.vw_product_profitability AS
(
	SELECT
		ProductKey, Product_Name, Brand, Category, Subcategory,
		SUM(Revenue) AS Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		SUM(Quantity) AS Units_Sold
	FROM ge.vw_sales_products_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY ProductKey, Product_Name, Brand, Category, Subcategory
)

-- Customers and Countries
CREATE OR ALTER VIEW ge.vw_sales_products_countries_fact AS
(
	SELECT
		sp.*,
		c.Country AS Customer_Country, c. Continent AS Customer_Continent
	FROM ge.vw_sales_products_fact AS sp
	LEFT JOIN ge.Customers AS c
	ON sp.CustomerKey = c.CustomerKey
)