use sqlworkout_DB

select * from customers
select * from dim_date
select * from products
select * from orders_aggregate
select * from order_lines
select * from targets_orders


select count(distinct customer_id) from customers


SELECT COUNT(DISTINCT product_id) AS Total_products 
FROM products;

SELECT COUNT(DISTINCT city) AS Total_cities 
FROM customers;

select customer_id, 
avg(order_qty) as avg_order from 
order_lines
group by customer_id
order by avg_order desc

-- What is the average delivery time for orders by city?
select * from customers;
select * from order_lines;
select * from customers

select c.city,
avg(datediff(DAY,ol.actual_delivery_date,ol.agreed_delivery_date)) from order_lines ol
inner join customers c
on c.customer_id = ol.customer_id
group by c.city

-- What is the average delivery time for on-time(OT) orders by city?
select * from orders_aggregate
select * from order_lines

select c.city,
avg(datediff(DAY,ol.actual_delivery_date,ol.agreed_delivery_date)) from order_lines ol
inner join customers c
on c.customer_id = ol.customer_id
inner join orders_aggregate oa
on oa.order_id = oa.order_id
group by c.city

--Ordered Based Analysis
 --Calculate the total number of orders, orders on time, orders in full, and OTIF (on-time and in full) orders for each city. 

WITH city_order_data AS (
    SELECT 
        customers.city,
        orders_aggregate.order_id,
        orders_aggregate.on_time,
        orders_aggregate.in_full,
        orders_aggregate.otif
    FROM orders_aggregate 
		INNER JOIN customers 
			ON orders_aggregate.customer_id = customers.customer_id
),
all_order_data AS (
    SELECT 	
        city,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) AS total_on_time,
        SUM(CASE WHEN in_full = 1 THEN 1 ELSE 0 END) AS total_in_full,
        SUM(CASE WHEN otif = 1 THEN 1 ELSE 0 END) AS total_otif
    FROM city_order_data
    GROUP BY city
)

SELECT 
    all_order_data.city,
    all_order_data.total_orders,
    all_order_data.total_on_time,
    all_order_data.total_in_full,
    all_order_data.total_otif,
    (SELECT COUNT(DISTINCT order_id) FROM orders_aggregate) AS overall_total_order
FROM all_order_data;


-- Provide insights into the distribution of the above metrics by customers within each city.

with customer_metrics as (
select 
c.customer_name,
sum(ol.order_qty) as total_orders,
sum( case when o.on_time = 1 then ol.order_qty  else 0 end)total_orders_on_time,
SUM(CASE WHEN o.in_full = 1 THEN ol.order_qty ELSE 0 END) total_orders_in_full,
SUM(CASE WHEN o.otif = 1 THEN ol.order_qty ELSE 0 END) as total_orders_otif
from order_lines ol 
inner join customers c on c.customer_id = ol.customer_id
inner join orders_aggregate o on o.order_id = ol.order_id
group by c.customer_name)

select customer_name,
    total_orders,
    total_orders_on_time,
    total_orders_in_full,
    total_orders_otif,
	ROUND((total_orders_on_time *100)/total_orders,2) as 'on_time_%',
	ROUND((total_orders_in_full*100.0)/total_orders, 2) AS 'in_full_%',
    ROUND((total_orders_otif*100.0)/total_orders, 2) AS 'otif_%'
FROM customer_metrics 
ORDER BY total_orders DESC;

-- Calculate the percentage variance between actual and target values for OT, IF, and OTIF metrics by city.

with actual as(
select c.city as  city,
sum(case when ol.on_time = 1 then 1 else 0 end) *100/ count(distinct ol.order_id) as actual_ot,
sum( case when ol.in_full = 1 then 1 else 0 end) *100/ count(distinct ol.order_id) as actual_if,
sum( case when ol.otif = 1 then 1 else 0 end ) *100 / count(distinct ol.order_id) as actual_otif
from orders_aggregate ol inner join
customers c 
on c.customer_id = ol.customer_id
group by city
),
target as(
select 
c.city,
sum(tor.column2) /count (distinct tor.column1) as target_ot,
sum(tor.column3) / count(distinct tor.column1) as target_if,
sum(tor.column4) / count(distinct tor.column1) as target_otif
from targets_orders tor
inner join 
customers c on c.customer_id = tor.column1
group by c.city)

select 
actual.city,
ROUND((actual.actual_ot - target.target_ot) * 100.0 / target.target_ot, 3) AS ot_varience,
	ROUND((actual.actual_if - target.target_if) * 100.0 / target.target_if, 3) AS if_varience,
	ROUND((actual.actual_otif - target.target_otif) * 100.0/ target.target_otif, 3) AS otif_varience
FROM actual
JOIN target ON actual.city = target.city;


-- Identify the top and bottom 5 customers based on total quantity ordered, in full quantity ordered, and OTIF quantity ordered.

select * from order_lines
select * from customers

-- -- Top 5 Cusotmers by Total_quantity_ordered: 

select TOP 5 c.customer_name as names,
sum(ol.order_qty) as total_orders
from customers c inner join order_lines ol 
on ol.customer_id = c.customer_id
group by c.customer_name
order by total_orders desc

-- Top 5 Cusotmers by infull_quantity_ordered: 

select TOP 5 c.customer_name as names,
sum(ol.delivery_qty) as infull_orders
from customers c inner join order_lines ol 
on ol.customer_id = c.customer_id
group by c.customer_name
order by infull_orders desc

select * from orders_aggregate

select oa.customer_id,
sum(case when oa.otif = 1 then ol.delivery_qty else 0 end) as otif_qty
from orders_aggregate oa
inner join order_lines ol on
oa.customer_id = ol.customer_id
group by oa.customer_id

-- Calculate the actual OT%, IF%, and OTIF% for each customer.

select customers.customer_name,
sum(case when orders_aggregate.in_full = 1 then 1 else 0 end) * 100.0 / count(distinct orders_aggregate.order_id) as actual_it,
sum(case when orders_aggregate.on_time = 1 then 1 else 0 end)* 100.0 / count( distinct orders_aggregate.order_id) as actual_ot,
SUM(CASE WHEN orders_aggregate.otif = 1 THEN 1 ELSE 0 END) * 100.0/ COUNT(DISTINCT orders_aggregate.order_id) AS actual_otif
	FROM orders_aggregate
    JOIN customers ON orders_aggregate.customer_id = customers.customer_id
    GROUP BY customers.customer_name 

-- Categorize orders by product category for each customer in descending order.

with customer_orders as (
select customers.customer_name,
products.category ,
count(distinct order_lines.order_id) as  Total_Orders
from order_lines 
inner join 
products on products.product_id = order_lines.product_id
inner join 
customers on customers.customer_id = order_lines.customer_id
group by customers.customer_name,products.category
)

SELECT 
	customer_orders.customer_name,
	SUM(CASE WHEN customer_orders.category = 'dairy' THEN customer_orders.Total_Orders ELSE 0 END) AS 'Dairy',
	SUM(CASE WHEN customer_orders.category = 'food' THEN customer_orders.Total_Orders ELSE 0 END) AS 'Food',
	SUM(CASE WHEN customer_orders.category = 'beverages' THEN customer_orders.Total_Orders ELSE 0 END) AS 'Beverages',
	SUM(customer_orders.Total_Orders) AS "Total_Orders"
FROM customer_orders
GROUP BY customer_orders.customer_name
ORDER BY "Total_Orders" DESC;

-- Categorize orders by product category for each city in descending order.
WITH customer_orders AS (
select customers.city,
products.category,
count(distinct order_lines.order_id ) as total_orders
from customers
inner join order_lines on
customers.customer_id = order_lines.customer_id
inner join
products
on products.product_id = order_lines.product_id
group by customers.city
,products.category
)

SELECT 
	customer_orders.city,
	SUM(CASE WHEN customer_orders.category = 'dairy' THEN customer_orders.total_orders ELSE 0 END) AS 'Dairy',
    SUM(CASE WHEN customer_orders.category = 'food' THEN customer_orders.total_orders ELSE 0 END) AS 'Food',
    SUM(CASE WHEN customer_orders.category = 'beverages' THEN customer_orders.total_orders ELSE 0 END) AS 'Beverages',
    SUM(customer_orders.total_orders) AS "Total_Orders"
FROM customer_orders
GROUP BY customer_orders.city 
ORDER BY "Total_Orders" DESC;

-- Determine the top 3 customers from each city based on their total order count and provide their OTIF%.

select * from customers
select * from order_lines

with cities as 

(select  customers.customer_name,
customers.city,
count(oa.order_id) as total_orders,
CONCAT((ROUND((count( case when oa.otif = 1 then (otif) end)*100 / count (otif)),2)),'%') as "OTIF%",
row_number()over(partition by customers.city order by count(oa.order_id)desc) as ranking
from customers join orders_aggregate oa on
customers.customer_id = oa.customer_id
group by customers.customer_name, customers.city
)

select * from cities where ranking in(1,2,3)


-- Identify the most and least ordered product by each customer.

with customer_products as (
select customers.customer_name,
products.product_name,
count(order_lines.product_id) as Product_count from 
customers inner join
order_lines on customers.customer_id = order_lines.customer_id
inner join products
on products.product_id = order_lines.product_id
group by customers.customer_name , products.product_name
),
customer_max_min_counts as (
select cp.customer_name,
max(Product_count) as max_product_count
, min(Product_count)as  min_product_count
from customer_products cp
group by cp.customer_name
)
SELECT
    cp.customer_name,
    MAX(CASE WHEN cp.Product_count = cmc.max_product_count THEN cp.product_name END) AS most_ordered_product,
    MAX(CASE WHEN cp.Product_count = cmc.min_product_count THEN cp.product_name END) AS least_ordered_product
FROM customer_products cp
JOIN customer_max_min_counts cmc ON cp.customer_name = cmc.customer_name
GROUP BY cp.customer_name, cmc.max_product_count, cmc.min_product_count
ORDER BY cp.customer_name;

-- Distribute the total product orders by their categories and calculate the percentage share. Also, identify the top and worst selling products for each city.
with city_categories as (
select customers.city,
products.product_name,
products.category,
count(ol.order_id) as total_orders
from order_lines ol 
inner join products
on products.product_id = ol.product_id
inner join customers
on customers.customer_id = ol.customer_id
group by customers.city,products.product_name,products.category)
,
categories_totals as(
select city, 
sum(case when category = 'dairy' then total_orders else 0 end) as dairy,
SUM(CASE WHEN category = 'food' THEN total_orders ELSE 0 END) AS food_total,
SUM(CASE WHEN category = 'beverages' THEN total_orders ELSE 0 END) AS beverages_total,
sum(total_orders) as total_orders from city_categories
group by city)

SELECT 
    cc.city,
    cc.category,
    SUM(cc.total_orders) AS total_orders,
    CONCAT(ROUND((SUM(cc.total_orders) * 100.0 / ct.total_orders), 2), '%') AS percent_share,
    (SELECT TOP 1 cc2.product_name FROM city_categories cc2 WHERE cc2.city = cc.city ORDER BY cc2.total_orders DESC) AS top_selling_products,
    (SELECT TOP 1 cc2.product_name FROM city_categories cc2 WHERE cc2.city = cc.city ORDER BY cc2.total_orders ASC) AS least_selling_products
FROM city_categories cc
JOIN categories_totals ct ON cc.city = ct.city
GROUP BY cc.city, cc.category, ct.total_orders
ORDER BY cc.city, percent_share DESC;

-- Investigate how the trend of on-time delivery varies over different months.
select * from order_lines
select 
month( order_placement_date) ,
sum(case when On_Time = 1 then 1 else 0 end) as on_time,
sum(case when On_Time = 1 then 1 else 0 end)*100.0 / count(ol.order_id) as percent_infull 
from order_lines ol 
group by MONTH(ol.order_placement_date) 
order by MONTH(ol.order_placement_date) 

-- Analyze the pattern of in-full deliveries across the course of months.

select 
month( order_placement_date) ,
sum(case when In_Full = 1 then 1 else 0 end) as in_full,
sum(case when In_Full = 1 then 1 else 0 end)*100.0 / count(ol.order_id) as percent_infull 
from order_lines ol 
group by MONTH(ol.order_placement_date) 
order by MONTH(ol.order_placement_date) 

-- Explore the trend of deliveries that are both on-time and in-full across different months.

select 
month( order_placement_date) as month ,
sum(case when On_Time_In_Full = 1 then 1 else 0 end) as on_time_in_full,
sum(case when On_Time_In_Full = 1 then 1 else 0 end)*100.0 / count(ol.order_id) as percent_on_time_in_Full
from order_lines ol 
group by MONTH(ol.order_placement_date) 
order by MONTH(ol.order_placement_date) 


SELECT 
    DATEPART(WEEKDAY, order_placement_date) AS Day_no,
	CASE DATEPART(WEEKDAY, order_placement_date)
	WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
     END AS Day_Name,
	 COUNT(order_id) AS Total_orders
FROM order_lines
GROUP BY DATEPART(WEEKDAY, order_placement_date)
ORDER BY Total_orders DESC;

-- Determine the average duration in days from order placement to delivery for all orders, categorized by city.

SELECT 
	c.city,
    AVG(DATEDIFF(DAY, ol.actual_delivery_date, ol.order_placement_date)) AS Average_days
FROM order_lines ol
INNER JOIN customers c ON ol.customer_id = c.customer_id
GROUP BY c.city
ORDER BY Average_days DESC;

-- Calculate the average lead time (time between order placement and delivery) for each individual customer.

select 
c.customer_name,
AVG(DATEDIFF(HOUR, ol.actual_delivery_date, ol.order_placement_date)) AS Average_Time
FROM order_lines ol
JOIN customers c ON ol.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY Average_Time;
     