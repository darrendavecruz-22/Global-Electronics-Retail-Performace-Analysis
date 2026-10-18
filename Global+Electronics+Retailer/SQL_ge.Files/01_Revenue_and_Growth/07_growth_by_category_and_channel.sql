-- Growth by Category and Channel

/*
Question:
Q1: Which product categories generate the most revenue and gross profit?
Q2: Which categories have the fastest year-over-year revenue growth?
Q3: Which categories contribute the most to the overall revenue increase or decrease?
Q4: Which sales channels generate the most revenue and gross profit?
Q5: Which channels have the highest year-over-year revenue growth?
Q6: Which channels are responsible for the largest revenue declines?
Q7: Which product categories perform best within each sales channel?
Q8: Which category-channel combinations contribute most to revenue growth?
*/

-- Setup: Shared view

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

-- Sol'n 1: Categories by revenue and gross profit
SELECT
	Category,
	SUM(Total_Revenue) AS Revenue,
	SUM(Total_Profit) AS Profit,
	CAST(ROUND(100.0 * SUM(Total_Revenue) / SUM(SUM(Total_Revenue)) OVER(), 2) AS DECIMAL(18,2)) AS Revenue_Share,
	CAST(ROUND(100.0 * SUM(Total_Profit) / SUM(SUM(Total_Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_Share,
	RANK() OVER(ORDER BY SUM(Total_Revenue) DESC) AS Revenue_rank,
	RANK() OVER(ORDER BY SUM(Total_Profit) DESC) AS Profit_rank
FROM ge.vw_category_channel_yearly
WHERE Year BETWEEN 2016 AND 2020
GROUP BY Category
ORDER BY Revenue DESC;

-- Sol'n 2: Fastest year-over-year growth by category
WITH CTE_category AS
(
	SELECT
		Category, Year, SUM(Total_Revenue) AS Revenue
	FROM ge.vw_category_channel_yearly
	WHERE Year BETWEEN 2016 AND 2020
	GROUP BY Category, Year
),

CTE_yoy_category AS
(
	SELECT
	*,
	LAG(Revenue) OVER(PARTITION BY Category ORDER BY Year) AS Prv_Revenue,
	CAST(ROUND(100.0 * (Revenue - LAG(Revenue) OVER(PARTITION BY Category ORDER BY Year)) /
		NULLIF(LAG(Revenue) OVER(PARTITION BY Category ORDER BY Year), 0), 2) AS DECIMAL(18,2)) AS Category_yoy
	FROM CTE_category
	WHERE Year BETWEEN 2016 AND 2020
)

SELECT
	Category, Year, Revenue, Category_yoy,
	RANK() OVER(PARTITION BY Year ORDER BY Category_yoy DESC) AS Growth_Rank
FROM CTE_yoy_category
WHERE Prv_Revenue IS NOT NULL
ORDER BY Year, RANK() OVER(PARTITION BY Year ORDER BY Category_yoy DESC);

-- Sol'n 3: Which categories drive the overall increase or decrease?
WITH CTE_category AS
(
	SELECT
		Category, Year, SUM(Total_Revenue) AS Revenue
	FROM ge.vw_category_channel_yearly
	WHERE Year BETWEEN 2016 AND 2020
	GROUP BY Category, Year
),

CTE_yearly AS
(
	SELECT
		Category, Year, Revenue, SUM(Revenue) OVER(PARTITION BY Year) AS Revenue_Year
	FROM CTE_category
	WHERE Year BETWEEN 2016 AND 2020
),

CTE_change AS
(
	 SELECT
		Year, Category, Revenue, Revenue_Year,
		LAG(Revenue) OVER(PARTITION BY Category ORDER BY Year) AS Prv_Revenue,
		Revenue - LAG(Revenue) OVER(PARTITION BY Category ORDER BY Year) AS Revenue_Change,
		SUM(Revenue) OVER(PARTITION BY Year) AS Total_Revenue_per_Year,
		LAG(Revenue_Year) OVER(PARTITION BY Category ORDER BY Year) AS Prv_Year_Total
	FROM CTE_yearly
)

SELECT
	Category, Year, Revenue_Change,
	CAST(ROUND(100.0 * Revenue_Change / NULLIF(Prv_Year_Total, 0), 2) AS DECIMAL(18,2)) AS Contribution_to_Growth,
	RANK() OVER(PARTITION BY Year ORDER BY ABS(Revenue_Change) DESC) AS Impact_Rank
FROM CTE_change
WHERE Revenue_Change IS NOT NULL
ORDER BY Year, RANK() OVER(PARTITION BY Year ORDER BY ABS(Revenue_Change) DESC);

-- Sol'n 4: Channels by revenue and gross profit
SELECT
	Channel, Year,
	SUM(Total_Revenue) AS Revenue,
	SUM(Total_Profit) AS Profit,
	100 * SUM(Total_Profit) / SUM(Total_Revenue) AS Profit_Margin,
	CAST(ROUND(100.0 * SUM(Total_Revenue) / SUM(SUM(Total_Revenue)) OVER(), 2) AS DECIMAL(18,2)) AS Revenue_Share,
	CAST(ROUND(100.0 * SUM(Total_Profit) / SUM(SUM(Total_Profit)) OVER(), 2) AS DECIMAL(18,2)) AS Profit_Share
FROM ge.vw_category_channel_yearly
WHERE Year BETWEEN 2016 AND 2020
GROUP BY Channel, Year;

-- Sol'n 5 & 6: Channel growth and the largest declines
WITH CTE_channel AS
(
	SELECT
		Channel, Year, SUM(Total_Revenue) AS Revenue
	FROM ge.vw_category_channel_yearly
	WHERE Year BETWEEN 2016 AND 2020
	GROUP BY Channel, Year
),

CTE_yoy_channel AS
(
	SELECT
		*,
		Revenue - LAG(Revenue) OVER(PARTITION BY Channel ORDER BY Year) AS Revenue_Change,
		ROUND(100.0 * (Revenue - LAG(Revenue) OVER(PARTITION BY Channel ORDER BY Year)) /
		      NULLIF(LAG(Revenue) OVER(PARTITION BY Channel ORDER BY Year), 0), 2) AS Channel_yoy
	FROM CTE_channel
)

SELECT
	Channel, Year, Revenue, Revenue_Change, Channel_yoy,
	RANK() OVER(PARTITION BY Year ORDER BY Channel_yoy DESC) AS Growth_Rank,
	CASE
		WHEN Revenue_Change < 0 THEN RANK() OVER(PARTITION BY Year, CASE WHEN Revenue_Change < 0 THEN 1 END ORDER BY Revenue_Change) END AS Decline_rank
FROM CTE_yoy_channel
WHERE Revenue_Change IS NOT NULL
ORDER BY Year, Channel;

-- Sol'n 7: Best categories within each channel
SELECT
	Category, Channel,
	SUM(Total_Revenue) AS Revenue,
	SUM(Total_Profit) AS Profit,
	CAST(ROUND(100.0 * SUM(Total_Revenue) / SUM(SUM(Total_Revenue)) OVER(PARTITION BY Channel), 2) AS DECIMAL(18,2)) AS Share_of_channel,
	RANK() OVER(PARTITION BY Channel ORDER BY SUM(Total_Revenue) DESC) AS Ranking_of_Channels
FROM ge.vw_category_channel_yearly
WHERE Year BETWEEN 2016 AND 2020
GROUP BY Category, Channel;

-- Sol'n 8: Category-channel combinations driving growth.
WITH CTE_category_channel AS
(
	SELECT
		Category, Channel, Year, SUM(Total_Revenue) AS Revenue
	FROM ge.vw_category_channel_yearly
	WHERE Year BETWEEN 2016 AND 2020
	GROUP BY Category, Channel, Year
),

CTE_share AS
(
	SELECT
		*,
		Revenue - LAG(Revenue) OVER(PARTITION BY Category, Channel ORDER BY Year) AS Revenue_Change,
		SUM(Revenue) OVER(PARTITION BY Year) AS Yearly_Revenue
	FROM CTE_category_channel
)

SELECT
	Category, Channel, Year, Revenue_Change,
	CAST(ROUND(100.0 * Revenue_Change / NULLIF(LAG(Revenue) OVER(PARTITION BY Category, Channel ORDER BY Year), 0), 2) AS DECIMAL(18,2)) AS Contribution,
	RANK() OVER(PARTITION BY Year ORDER BY Revenue_Change DESC) AS Growth_rank
FROM CTE_share
WHERE Revenue_Change IS NOT NULL;