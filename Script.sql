-- Creating the database

drop database if exists superstore;
create database if not exists superstore;
use superstore;

-- creating the table to import data

drop table if exists superstore_sales;

CREATE TABLE superstore_sales (
    row_id INT PRIMARY KEY,
    order_priority VARCHAR(255),
    discount DOUBLE,
    unit_price DOUBLE,
    shipping_cost DOUBLE,
    customer_id INT,
    customer_name VARCHAR(255),
    ship_mode VARCHAR(255),
    customer_segment VARCHAR(255),
    product_category VARCHAR(255),
    product_sub_category VARCHAR(255),
    product_name VARCHAR(255),
    product_container VARCHAR(255),
    product_base_margin DOUBLE,
    region VARCHAR(255),
    manager VARCHAR(255),
    state_province VARCHAR(255),
    city VARCHAR(255),
    postal_code VARCHAR(255),
    order_date DATE,
    ship_date DATE,
    profit DOUBLE,
    quantity_ordered INT,
    sales DOUBLE,
    order_id INT,
    return_status VARCHAR(255)
);
/*
The necessary cleaning and formatting of the values were done before importing
- Setting the null values to zero in the column Product_Base_Margin
- Taking the date in proper format YYYY-MM-DD
*/
-- Loading data into the table

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Data/superstore/Superstore Sales Data.csv"
INTO TABLE superstore_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Exploring the data

SELECT 
    *
FROM
    superstore_sales
ORDER BY row_id
LIMIT 10;

-- checking for null values

SELECT 
    *
FROM
    superstore_sales
WHERE
    order_id IS NULL OR order_date IS NULL
        OR ship_date IS NULL
        OR customer_id IS NULL
        OR customer_name IS NULL
        OR region IS NULL
        OR city IS NULL
        OR postal_code IS NULL
        OR product_category IS NULL
        OR product_sub_category IS NULL
        OR product_name IS NULL
        OR sales IS NULL
        OR profit IS NULL;


-- EXPLORATORY DATA ANALYSIS(EDA)

SELECT 
    product_name, ROUND(SUM(sales)) AS total_sales
FROM
    superstore_sales
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 10;

-- most profitable region
SELECT 
    region, ROUND(SUM(profit)) AS total_profit
FROM
    superstore_sales
GROUP BY region
ORDER BY total_profit DESC;

-- order trends over time

SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    COUNT(*) AS orders
FROM
    superstore_sales
GROUP BY year , month
ORDER BY year , month;

-- Recency, Frequency and monetary value calculation (RFM Segmentation)
use superstore;
drop table if exists rfm_base;
create table rfm_base as
select 
	customer_id,
    max(order_date) as last_order_date,
    count(order_id) as frequency,
    round(sum(sales), 2) as monetary_value
from superstore_sales
group by customer_id;

select * from rfm_base limit 10;

set sql_safe_updates = 0;

alter table superstore_sales drop column recency;
alter table rfm_base add column recency int;
update rfm_base set recency = datediff((select max(order_date) from superstore_sales), last_order_date);

alter table rfm_base
add column recency_score int,
add column frequency_score int,
add column monetary_score int;

-- Assigning the recency score (lower the difference higher the score)

UPDATE rfm_base 
JOIN (
    SELECT 
        customer_id,
        recency,
        NTILE(5) OVER (ORDER BY recency ASC) AS recency_score
    FROM rfm_base
) AS rfm_scores 
ON rfm_base.customer_id = rfm_scores.customer_id
SET rfm_base.recency_score = rfm_scores.recency_score;

UPDATE rfm_base 
JOIN (
    SELECT 
        customer_id,
        NTILE(5) OVER (ORDER BY frequency DESC) AS frequency_score
    FROM rfm_base
) AS rfm_scores 
ON rfm_base.customer_id = rfm_scores.customer_id
SET rfm_base.frequency_score = rfm_scores.frequency_score;

UPDATE rfm_base 
JOIN (
    SELECT 
        customer_id,
        NTILE(5) OVER (ORDER BY monetary_value DESC) AS monetary_score
    FROM rfm_base
) AS rfm_scores 
ON rfm_base.customer_id = rfm_scores.customer_id
SET rfm_base.monetary_score = rfm_scores.monetary_score;


ALTER TABLE rfm_base ADD COLUMN rfm_segment VARCHAR(10);


UPDATE rfm_base
SET rfm_segment = CONCAT(recency_score, frequency_score, monetary_score);


SELECT 
    customer_id, 
    recency, frequency, monetary_value, 
    recency_score, frequency_score, monetary_score, 
    rfm_segment
FROM rfm_base
ORDER BY rfm_segment DESC;




