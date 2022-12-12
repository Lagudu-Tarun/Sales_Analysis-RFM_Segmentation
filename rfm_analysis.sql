-- Analyzing sales data to create a customer segmentation analysis using the RFM technique.

select * from sales_data_sample
LIMIT 10;

-- Checking the data types of columns

DESCRIBE sales_data_sample;

-- ORDERDATE is of text data type
SET SQL_SAFE_UPDATES=0;


UPDATE sales_data_sample
SET ORDERDATE = (
IF(
    DATE_FORMAT(STR_TO_DATE(ORDERDATE, '%m/%d/%Y %H:%i'), '%Y-%m-%d %H:%i:%s') IS NULL,
    NULL,
    DATE_FORMAT(STR_TO_DATE(ORDERDATE, '%m/%d/%Y %H:%i'), '%Y-%m-%d %H:%i:%s')
  )
);

-- This statement uses the STR_TO_DATE() function to convert the value ORDERDATE to a date and time value, and 
-- then uses the DATE_FORMAT() function to format the value. 
-- If the result of the DATE_FORMAT() function is NULL, it means the value is not a valid date and time,
--  and the statement will insert a NULL value instead. Otherwise, the formatted value will be inserted into the table.

ALTER TABLE sales_data_sample    
MODIFY ORDERDATE DATETIME;  

-- Inspecting unique values

select distinct status from sales_data_sample;
select distinct DEALSIZE from sales_data_sample;
select distinct PRODUCTLINE from sales_data_sample;
select distinct COUNTRY from sales_data_sample;
select distinct TERRITORY from sales_data_sample;
select distinct year_id from sales_data_sample;


-- A) Analysis of Sales

-- 1) Total sales per each product line

select PRODUCTLINE,ROUND(SUM(SALES),2) as Total_Revenue
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC;

-- Classics cars has the highest sales whereas Trains has the least

-- 2) Total sales per each year

select YEAR_ID,ROUND(SUM(SALES),2) as Total_Revenue
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC;

-- Highest sales occuredin the year 2004


select YEAR_ID,PRODUCTLINE,ROUND(SUM(SALES),2) as Total_Revenue
FROM sales_data_sample
GROUP BY YEAR_ID,PRODUCTLINE;

-- 3)  Total sales per each Deal Size

select DEALSIZE,ROUND(SUM(SALES),2) as Total_Revenue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC;

-- Medium deal size has the highest revenue

-- Best month for Highest sales for each year

select MONTH_ID,ROUND(SUM(SALES),2) as Total_Revenue,COUNT(ORDERNUMBER) as order_count
FROM sales_data_sample
WHERE YEAR_ID = '2005'
GROUP BY MONTH_ID
ORDER BY 2 DESC;

-- In the year 2003 & 2004 ,month 11 (November) has highest sales

-- Top products sold in November

select MONTH_ID,PRODUCTLINE,ROUND(SUM(SALES),2) as Total_Revenue,COUNT(ORDERNUMBER) as order_count
FROM sales_data_sample
WHERE MONTH_ID = '11' 
GROUP BY MONTH_ID,PRODUCTLINE
ORDER BY 2 DESC;

-- Vintage Cars has the highest sales in the month of November

-- What is the best product in for each country for each year

select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from sales_data_sample
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc;

-- Which city generates the highest revenue 

select CITY, sum(sales) Revenue
from sales_data_sample
group by  CITY
order by 2 desc;

-- Madrid generated the highest revenue.


-- RFM ANALYSIS

-- Recency - Last order date , Frequency - Total no of orders , Monetary - Total amount spent

-- CREATE TEMPORARY TABLE RFM_data

-- CREATE TEMPORARY TABLE rfm_data as

DROP TABLE IF EXISTS rfm_data;

CREATE TEMPORARY TABLE rfm_data as

WITH RFM AS
(
WITH date_convert as
(SELECT CUSTOMERNAME,

		max(ORDERDATE) as latest_ordere_date,
        
        (SELECT max(ORDERDATE) from sales_data_sample) as recent_date,  
                      
	   ROUND(SUM(SALES),2) as Total_sales,
       ROUND(AVG(SALES),2) as AVG_Sales,
       COUNT(ORDERLINENUMBER) as Frequency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
)

SELECT *, timestampdiff( DAY,latest_ordere_date, recent_date
                      ) AS Recency
 from date_convert                     
),

-- The MySQL NTILE() function divides rows in a sorted partition into a specific number of groups. 
-- Each group is assigned a bucket number starting at one. For each row, 
-- the NTILE() function returns a bucket number representing the group to which the row belongs.


RFM_cal as
(
SELECT *,
-- Frequency & Total_sales are higher the better whereas Recency is lower the value
	NTILE (4) OVER (ORDER BY Recency desc) RFM_Recency, -- when recency is high the score is low
	NTILE (4) OVER (ORDER BY Frequency) RFM_Frequency,
	NTILE (4) OVER (ORDER BY Total_sales) RFM_MonetaryValue
from RFM
),

CTES1 as 
(
SELECT rc.*, 
	  ( RFM_Recency + RFM_Frequency + RFM_MonetaryValue ) as rfm_total,
	  ( (RFM_Recency*100) + (RFM_Frequency*10) + (RFM_MonetaryValue*1) ) as rfm_value 
from RFM_cal as rc
)

SELECT *
FROM CTES1;



SELECT * from rfm_data;


-- "VIP" group for customers who have high values for all three metrics,
-- "loyal" group for customers who have high values for frequency and monetary value but a lower recency value, and
-- "potential" group for customers who have a high recency value but lower values for frequency and monetary value


select CUSTOMERNAME , rfm_recency, rfm_frequency, RFM_MonetaryValue,
	case 
		when rfm_value in (111, 112 ,113,114,121, 122, 123,124, 131,132,133, 134, 141,142, 143) then 'At-risk group'  -- lost customers
		when rfm_value in (244, 144, 211, 212,221,234,232) then 'potential' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_value in (222, 223, 233, 322,331,311, 411,412,413,423,421) then 'Active'
		when rfm_value in (344,323, 333,321, 422, 332, 432) then 'Loyal' -- (Customers who buy often & recently, but at low price points)
		when rfm_value in (444,443,434,433,343,333,334) then 'VIP'
	end rfm_segment

from rfm_data;


-- We can then tailor our marketing efforts to each customer segment, based on their unique RFM values. 
-- For example, we could offer special promotions or discounts to the VIP group to encourage them to continue making purchases,
-- send personalized emails to the loyal group to thank them for their business and keep them engaged,
-- and offer introductory discounts to the potential group to encourage them to make their first purchase.