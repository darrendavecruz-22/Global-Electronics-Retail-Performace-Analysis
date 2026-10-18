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

CREATE OR ALTER VIEW ge.vw_monthly_summary AS
(	
	SELECT
		YEAR(Order_Date) AS Year,
		DATEPART(quarter, Order_Date) AS Quarter,
		MONTH(Order_Date) AS Month,
		SUM(Revenue) AS Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		SUM(Quantity) AS Total_Units,
		COUNT(DISTINCT Order_Number) AS Total_Orders
	FROM ge.vw_sales_products_fact
	GROUP BY YEAR(Order_Date), DATEPART(quarter, Order_Date), MONTH(Order_Date)
)
GO

CREATE OR ALTER VIEW ge.vw_category_channel_yearly AS
(
	SELECT
		Category,
		YEAR(Order_Date) AS Year,
		CASE WHEN StoreKey = 0 THEN 'Online' ELSE 'In-store' END AS Channel,
		SUM(Revenue) AS Total_Revenue,
		SUM(Gross_Profit) AS Total_Profit,
		SUM(Quantity) AS Total_Units
	FROM ge.vw_sales_products_fact
	GROUP BY Category, YEAR(Order_Date), CASE WHEN StoreKey = 0 THEN 'Online' ELSE 'In-store' END
)
GO

SELECT SUM(Revenue), SUM(Gross_Profit) FROM ge.vw_sales_products_fact
