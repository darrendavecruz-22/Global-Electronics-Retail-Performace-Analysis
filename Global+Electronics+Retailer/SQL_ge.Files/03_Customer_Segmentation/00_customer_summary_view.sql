-- Views

-- Setup: one row per customer who has ordered (reused by every file in this part)
-- Reference date = last order date in the data (never GETDATE()), used for age and recency.
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

-- Customer Orders
-- Setup: one row per order, with its position and the gap to the customer's previous
CREATE OR ALTER VIEW ge.vw_customer_orders AS
WITH CTE_orders AS
(
	SELECT
		CustomerKey, Order_Number, MIN(Order_Date) AS Order_Date
	FROM ge.vw_sales_products_fact
	GROUP BY CustomerKey, Order_Number
)
-- Main Query
SELECT
	CustomerKey, Order_Number, Order_Date,
	ROW_NUMBER() OVER(PARTITION BY CustomerKey ORDER BY Order_Date, Order_Number) AS Order_no,
	-- Order date gap
	DATEDIFF(day, LAG(Order_Date) OVER(PARTITION BY CustomerKey ORDER BY Order_Date, Order_Number), Order_Date) AS Order_days_gap
FROM CTE_orders
GO

-- Customer Recency, Frequency, and Monetary Value (RFM)
CREATE OR ALTER VIEW ge.vw_customer_rfm AS 
WITH CTE_base AS
(
	SELECT 
		CustomerKey, Name, Country, Continent, Orders, Revenue, Profit,
		DATEDIFF(day, Last_Order_Date, Ref_Date) AS Recency_Days
	FROM ge.vw_customer_summary
),

CTE_score As
(
	SELECT
		*,
		-- Recency Score: 1 = Oldest order and 5 = Newest order
		NTILE(5) OVER(ORDER BY Recency_Days DESC, CustomerKey) AS R_score,
		-- Frequency Score: Number of orders with 1 is the least and +5 is the most
		CASE WHEN Orders >= 5 THEN 5 ELSE Orders END AS F_score,
		-- Monetary Value Score: 1 is the lowest profit and 5 is the highest
		NTILE(5) OVER(ORDER BY Profit, CustomerKey) AS M_score
	FROM CTE_base
)

-- Main Query
SELECT
	*,
	-- RFM Segment: Champions, Loyal, Recent customers, At risk, Needs Attention, Lapsed
	CASE
		WHEN R_score >= 4 AND F_score >= 4 THEN 'Champions'
		WHEN R_score >= 3 AND F_score >= 3 THEN 'Loyal'
		WHEN R_score >= 4 AND F_score <= 2 THEN 'Recent Customers'
		WHEN R_score <= 2 AND F_score >= 3 THEN 'At Risk'
		WHEN R_score = 3 AND F_score <= 2 THEN 'Needs Attention'
		ELSE 'Lapsed'
	END AS RFM_Segment
FROM CTE_score
GO

-- Overall Customer Segment View (Customer summary and Customer rfm)
CREATE OR ALTER VIEW ge.vw_customer_segments AS
SELECT
    s.CustomerKey, s.Name, s.Gender, s.Country, s.Continent,
    s.Age, s.Age_bracket, s.Age_bracket_order,
    s.First_Order_Date, s.Last_Order_Date,
    s.Orders, s.Units_sold, s.Revenue, s.Profit,
    r.Recency_Days, r.R_score, r.F_score, r.M_score, r.RFM_Segment,
    CASE r.RFM_Segment
        WHEN 'Champions' THEN 1 WHEN 'Loyal' THEN 2
        WHEN 'Recent Customers' THEN 3 WHEN 'Needs Attention' THEN 4
        WHEN 'At Risk' THEN 5 ELSE 6
    END AS Segment_order   -- for sorting charts in Power BI
FROM ge.vw_customer_summary AS s
JOIN ge.vw_customer_rfm AS r ON r.CustomerKey = s.CustomerKey;
GO

CREATE OR ALTER VIEW ge.vw_customer_value_decile AS
SELECT
    CustomerKey,
    SUM(Gross_Profit) AS Lifetime_Gross_Profit,
    NTILE(10) OVER (ORDER BY SUM(Gross_Profit) DESC, CustomerKey) AS Value_Decile
FROM ge.vw_sales_products_fact
GROUP BY CustomerKey
GO