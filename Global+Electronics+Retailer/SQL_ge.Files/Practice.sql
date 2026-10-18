-- Count the Number of Male Customers
SELECT
	COUNT(Gender)
FROM ge.Customers
WHERE Gender = 'Male'

-- Count the Number of Female Customers
SELECT
	COUNT(Gender)
FROM ge.Customers
WHERE Gender = 'Female'

-- Count the number of customers per countries
SELECT
	Country,
	COUNT(CustomerKey) AS No_of_Customers
FROM ge.Customers
GROUP BY
	Country

-- Count the number of male customers per countries
SELECT
	Country,
	COUNT(CustomerKey) AS No_of_Customers
FROM ge.Customers
WHERE Gender = 'Male'
GROUP BY
	Country

-- Count the number of female customers per countries
SELECT
	Country,
	COUNT(CustomerKey) AS No_of_Customers
FROM ge.Customers
WHERE Gender = 'Female'
GROUP BY
	Country

-- Rank the countries base on total customers from highest to lowest
SELECT
	*,
	ROW_NUMBER() OVER(ORDER BY No_of_Customers DESC) AS Ranking
FROM
(
	SELECT
		Country,
		COUNT(CustomerKey) AS No_of_Customers
	FROM ge.Customers
	GROUP BY
		Country
) AS t

-- Find the names of the customers who had same names
SELECT
	Name
FROM
(
	SELECT
		Name,
		ROW_NUMBER() OVER(PARTITION BY Name ORDER BY Name) AS rn
	FROM ge.Customers
) AS t
WHERE rn > 1