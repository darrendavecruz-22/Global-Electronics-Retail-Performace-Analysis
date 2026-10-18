-- 06_country_category_profitability

/*
Questions:
Q1: Which categories contribute the most profit in each country?
Q2: Does any country rely on a category much more or less than the company overall?
*/

-- Check if there are 64 rows (8 countries x 8 categories) and the same profit total.
SELECT
	COUNT(*) AS Country_Category_Rows,
	ROUND(SUM(Gross_Profit), 2) AS Total_Profit
FROM
(
	SELECT Customer_Country, Category, SUM(Gross_Profit) AS Gross_Profit
	FROM ge.vw_sales_products_countries_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY Customer_Country, Category
) AS t;

-- Sol'n Q1 and Q2: Profit by country and category
SELECT
	Customer_Country AS Country, Category, 
	
	-- Total revenue, Total profit, Profit margin.
	SUM(Revenue) AS Revenue, 
	SUM(Gross_Profit) AS Profit,
	CAST(ROUND(100.0 * SUM(Revenue) / SUM(Gross_Profit), 2) AS DECIMAL(18,2)) AS Profit_Margin,

	-- Q1: how much of the country's profit a particular category provides.
	CAST(ROUND(100.0 * SUM(Gross_Profit) / SUM(SUM(Gross_Profit)) OVER(PARTITION BY Customer_Country), 2) AS DECIMAL(18, 2)) AS Profit_share_country,
	RANK() OVER(PARTITION BY Customer_Country ORDER BY SUM(Gross_Profit) DESC) AS Country_rank,

	-- Q2: the category's share of profit across all countries, and the gap versus this country.
	CAST(ROUND(100.0 * SUM(SUM(Gross_Profit)) OVER(PARTITION BY Category) / SUM(SUM(Gross_Profit)) OVER(), 2) AS DECIMAL(18, 2)) AS Category_Share,
	CAST(ROUND(
				100.0 * SUM(Gross_Profit) / SUM(SUM(Gross_Profit)) OVER(PARTITION BY Customer_Country) -
				100.0 * SUM(SUM(Gross_Profit)) OVER(PARTITION BY Category) / SUM(SUM(Gross_Profit)) OVER(), 2)
	AS DECIMAL(18, 2)) AS Gap_vs_Comapny
FROM ge.vw_sales_products_countries_fact
WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
GROUP BY Customer_Country, Category
ORDER BY Country, Country_rank;