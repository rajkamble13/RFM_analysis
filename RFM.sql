SELECT * FROM [dbo].[sales_data]

-- DISTINCT VALUES

SELECT DISTINCT status FROM sales_data
SELECT DISTINCT year_id FROM sales_data
SELECT DISTINCT productline FROM sales_data
SELECT DISTINCT city FROM sales_data
SELECT DISTINCT state FROM sales_data
SELECT DISTINCT country FROM sales_data
SELECT DISTINCT territory FROM sales_data
SELECT DISTINCT dealsize FROM sales_data



-- GROUPING SALES BY PRODUCTLINE

SELECT productline, SUM(sales) total_sales
FROM sales_data
GROUP BY productline
ORDER BY 2 DESC


SELECT year_id, SUM(sales) total_sales
FROM sales_data
GROUP BY year_id
ORDER BY 2 DESC


SELECT dealsize, SUM(sales) total_sales
FROM sales_data
GROUP BY dealsize
ORDER BY 2 DESC



-- BEST MONTH FOR SALE IN A SPECIFIC YEAR

SELECT month_id, SUM(sales) AS total_sales, COUNT(ordernumber) AS order_count
FROM sales_data
WHERE year_id = 2003      -- (change year to see rest)
GROUP BY month_id
ORDER BY 2 DESC



-- NOVEMBER SEEMS THE BEST MONTH, WHAT PRODUCT THEY SELL IN NOVEMBER?

SELECT productline, month_id, SUM(sales) AS total_sales, COUNT(ordernumber) AS order_count
FROM sales_data
WHERE year_id = 2004 AND month_id = 11     -- (change year to see rest)
GROUP BY productline, month_id
ORDER BY 3 DESC



-- WHO'S THE BEST CUSTOMER (USING RFM)
-- THEN INSERTING THE RESULT INTO TEMP TABLE 'RFM'

DROP TABLE IF EXISTS #RFM
;WITH RFM AS
			(
			SELECT customername, 
			SUM(sales) AS MonetaryValue,
			AVG(sales) AS AvgMonetaryValue, 
			COUNT(ordernumber) AS frequency,	
			MAX (orderdate) AS last_order_date,
			(SELECT MAX (orderdate) FROM [dbo].[sales_data]) AS max_order_date,
			DATEDIFF(DD, MAX (orderdate), (SELECT MAX (orderdate) FROM [dbo].[sales_data])) AS recency
			FROM [dbo].[sales_data]
			GROUP BY customername
			),
rfm_calc AS
	(
	SELECT *,
	NTILE(4) OVER(ORDER BY recency) AS rfm_recency,
	NTILE(4) OVER(ORDER BY frequency) AS rfm_frequency,
	NTILE(4) OVER(ORDER BY MonetaryValue) AS rfm_monetary
	FROM RFM
	)
SELECT 
	r.*, rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
	cast(rfm_recency AS varchar) + cast(rfm_frequency AS varchar) + cast(rfm_monetary AS varchar) rfm_cell_string
INTO #RFM
FROM rfm_calc r
	
		
-- CATEGORIZING CUSTOMERS FROM ABOVE SEGMENTATION

SELECT customername, rfm_recency, rfm_frequency, rfm_monetary, 
	CASE
		WHEN rfm_cell_string IN (111, 112, 113, 114, 121, 122, 123, 131, 132, 141, 211, 212) then 'lost customers'     -- (lost customers)
		WHEN rfm_cell_string IN (124, 133, 134, 143, 144, 223, 224, 233, 234, 243, 244) then 'slipping away, cannot lose'  -- (Big spenders, who haven't purchased recently
		WHEN rfm_cell_string IN (311, 312, 313, 314, 323, 324, 411, 412, 413, 414, 421, 422) then 'new customers'
		WHEN rfm_cell_string IN (222, 231, 232, 241, 242) then 'potential churners' -- (customers who can be converted to active or loyal)
		WHEN rfm_cell_string IN (321, 322, 331, 332, 341, 342, 431, 432, 441, 442) then 'active'  -- (customers who buy often & recently but at low price)
		WHEN rfm_cell_string IN (333, 334, 343, 344, 423, 424, 433, 434, 443, 444) then 'loyal'  -- (customers who buy often & recently & also at decent price)
	END rfm_segment
FROM #RFM



-- WHAT PRODUCTS ARE MOST OFTEN SOLD TOGETHER?

SELECT DISTINCT ordernumber ,STUFF
		(
		(SELECT ',' + productcode
		FROM [dbo].[sales_data] p
		WHERE ordernumber in
			(
			SELECT ordernumber
			FROM
				(
				SELECT ordernumber, count(*) rn 
				FROM [dbo].[sales_data]
				WHERE status = 'Shipped'
				GROUP BY ordernumber
				)m
			WHERE rn = 2      --(change the value to 3 to see orders having 3 similar products)
			) 
		and p.ordernumber = s.ordernumber
		for xml path('')),
		1, 1, '') AS product_codes
FROM [dbo].[sales_data] s
order by 2 desc

--(WITH THE ABOVE RESULTS WE CAN SEE THAT ordernumber {10243 and 10409} have same productcodes and {10102 and 10256} have same productcodes)



