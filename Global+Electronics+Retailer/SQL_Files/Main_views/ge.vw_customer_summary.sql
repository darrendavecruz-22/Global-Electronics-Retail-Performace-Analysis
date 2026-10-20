/* =============================================================================
   View: ge.vw_customer_summary
   Purpose: Customer-level summary for segmentation. Combines each customer's 
   demographics with their lifetime order activity and adds age 
   and age bracket. Will be used later to combine with other views.

   Notes: Aggregates the sales fact view by customer, then joins the
   result to ge.Customers for demographics. Age is measured on the
   last order date in the dataset instead of today's date, so the
   results stay stable.
   ============================================================================= */

CREATE OR ALTER VIEW ge.vw_customer_summary AS
WITH CTE_reference AS
(
	-- Latest Date
	SELECT MAX(Order_Date) AS Ref_date FROM ge.vw_sales_products_fact
),

CTE_customer AS 
(
	SELECT
		CustomerKey,

		-- First_order_date, Last_order_date, and Total orders
		MIN(Order_Date) AS First_Order_Date,
		MAX(Order_Date) AS Last_Order_Date,
		COUNT(DISTINCT Order_Number) AS Orders,

		-- Units sold, revenue, profit
		SUM(Quantity) AS Units_sold,
		SUM(Revenue) AS Revenue,
		SUM(Gross_Profit) AS Profit
	FROM ge.vw_sales_products_fact
	GROUP BY CustomerKey
)

SELECT
	c.CustomerKey, c.Name, c.Gender, c.Country, c.Continent, c.Birthday,
	r.Ref_date,
	a.Age,

	-- Age bracket
	CASE
		WHEN a.Age < 25 THEN 'Under 25'
		WHEN a.Age < 35 THEN '25-34'
		WHEN a.Age < 45 THEN '35-44'
		WHEN a.Age < 55 THEN '45-54'
		WHEN a.Age < 65 THEN '55-64'
		ELSE '65+'
	END AS Age_bracket,

	-- Age Bracket Order
	CASE
		WHEN a.Age < 25 THEN 1
		WHEN a.Age < 35 THEN 2
		WHEN a.Age < 45 THEN 3
		WHEN a.Age < 55 THEN 4
		WHEN a.Age < 65 THEN 5
		ELSE 6
	END AS Age_bracket_order,

	s.First_Order_Date, s.Last_Order_Date, s.Orders, s.Units_sold, s.Revenue, s.Profit

FROM CTE_customer AS s
JOIN ge.Customers AS c ON c.CustomerKey = s.CustomerKey
CROSS JOIN CTE_reference AS r
CROSS APPLY
(
	-- age in whole years on the reference date
	SELECT
		DATEDIFF(year, c.Birthday, r.Ref_date) -
		CASE WHEN DATEADD(year, DATEDIFF(year, c.Birthday, r.Ref_date), c.Birthday) > r.Ref_date THEN 1 ELSE 0 END AS Age
) AS a

GO