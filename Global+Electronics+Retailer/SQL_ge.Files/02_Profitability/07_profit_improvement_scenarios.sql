-- 07_profit_improvement_scenarios (Break-Even)

/*
Question:
Q1: If we raise prices on the lowest-margin categories, how much volume can we lose
    before the price increase stops paying off (the break-even volume loss)?
*/

WITH CTE_cat AS
(
	SELECT
		Category,
		CAST(SUM(Revenue) AS float)      AS Revenue,
		CAST(SUM(Gross_Profit) AS float) AS Profit
	FROM ge.vw_sales_products_fact
	WHERE YEAR(Order_Date) BETWEEN 2016 AND 2020
	GROUP BY Category
),
CTE_target AS
(
	-- the 3 categories with the lowest profit margin
	SELECT TOP 3 Category, Revenue, Profit, 100.0 * Profit / Revenue AS Margin
	FROM CTE_cat
	ORDER BY Profit / Revenue ASC
),
CTE_price AS (SELECT Price_Up FROM (VALUES (0.02), (0.05), (0.10)) AS v(Price_Up)),
CTE_loss  AS (SELECT Vol_Loss FROM (VALUES (0.00), (0.02), (0.05), (0.10)) AS v(Vol_Loss)),

CTE_calc AS
(
	SELECT
		t.Category, t.Revenue, t.Profit, t.Margin,
		p.Price_Up, l.Vol_Loss,
		-- new profit = remaining volume x (new revenue - unchanged cost per unit sold)
		(1 - l.Vol_Loss) * (t.Profit + p.Price_Up * t.Revenue)         AS New_Profit,
		(1 - l.Vol_Loss) * t.Revenue * (1 + p.Price_Up)                AS New_Revenue,
		-- volume loss at which profit change is exactly zero
		p.Price_Up * t.Revenue / (t.Profit + p.Price_Up * t.Revenue)   AS Break_Even_Loss
	FROM CTE_target t
	CROSS JOIN CTE_price p
	CROSS JOIN CTE_loss l
)
SELECT
	Category,
	ROUND(Margin, 2)                      AS Current_Margin,
	ROUND(100 * Price_Up, 0)              AS Price_Increase_pct,
	ROUND(100 * Vol_Loss, 0)              AS Assumed_Volume_Loss_pct,
	ROUND(Profit, 0)                      AS Base_Profit,
	ROUND(New_Profit, 0)                  AS New_Profit,
	ROUND(New_Profit - Profit, 0)         AS Profit_Change,
	ROUND(100.0 * (New_Profit - Profit) / Profit, 2) AS Profit_Change_pct,
	ROUND(100.0 * New_Profit / New_Revenue, 2)       AS New_Margin,
	ROUND(100 * Break_Even_Loss, 2)       AS Break_Even_Volume_Loss_pct,
	CASE WHEN New_Profit > Profit THEN 'Profit up' ELSE 'Profit down' END AS Result
FROM CTE_calc
ORDER BY Category, Price_Increase_pct, Assumed_Volume_Loss_pct;