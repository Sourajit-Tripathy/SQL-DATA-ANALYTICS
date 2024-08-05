use foodie_DB
select * from subscription
select * from plans

-- How many customers has Foodie-Fi ever had?

select count(customer_id) as total_Customers from subscription

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select datepart(month, start_date) as months, count( distinct start_date) as monthly_subscription from subscription
group by datepart(month, start_date) 
order by datepart(month, start_date) 

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select
p.plan_id,
p.plan_name,
count(*) as total_events
from plans p
join subscription s
on p.plan_id = s.plan_id
where year(start_date) > 2020
group  by p.plan_id,p.plan_name;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

with total_customer as (
select count (distinct customer_id) as total_Customers from subscription)
, 
churned_customer as 
(
select count(distinct(customer_id)) as Number_of_churned_customer from subscription s left join plans p
on s.plan_id = p.plan_id
where p.plan_name = 'churn'
)

select Number_of_churned_customer ,
CAST(Number_of_churned_customer as float) * 100 / CAST(total_customers as float) as churned_percent
from total_customer, churned_customer


WITH CTE AS(
SELECT *, 
LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) As next_plan
FROM subscription
) 
SELECT 
plan_name , 
COUNT(next_plan) as number_churn, 
CAST(count(next_plan) AS FLOAT) * 100 / (select count(distinct customer_id) from subscription) as perc_straight_churn
FROM CTE c
LEFT JOIN plans p ON c.next_plan = p.plan_id
WHERE next_plan = 4 and c.plan_id = 0
GROUP BY plan_name;

--6. What is the number and percentage of customer plans after their initial free trial?

with cte as (select *,
lead(plan_id,1) over(partition by customer_id order by plan_id) as next_plan from subscription
)

select plan_name,
count(*)as num_plan,
cast(count(next_plan) as float) * 100 / (select count(distinct customer_id) from subscription) as perc_next_plan
FROM CTE c left join plans p 
ON c.next_plan = p.plan_id
WHERE  c.plan_id = 0 and next_plan is not NULL
GROUP BY plan_name,next_plan;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

with CTE as(
select *,LEAD(start_date,1) over(partition by customer_id order by plan_id) as next_date from subscription
)
SELECT C.plan_id,
plan_name, 
count(C.plan_id)  AS customer_count,  
(CAST(count(C.plan_id) AS Float) *100 / (select count(distinct customer_id) FROM subscription) ) as Percentage_customer
FROM CTE c
LEFT JOIN plans P ON C.plan_id= P.plan_id
WHERE c.next_date is NULL or c.next_date >'2020-12-31' 
GROUP BY C.plan_id,plan_name
ORDER BY plan_id

-- 8. How many customers have upgraded to an annual plan in 2020?

select plans.plan_name, count(subscription.plan_id) as total_plan_count from plans
join subscription on plans.plan_id = subscription.plan_id
where plan_name = 'pro annual' and start_date <='2020-12-31'
GROUP BY plan_name 

-- 9. How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?

with actual_CTE as
( select customer_id, start_date 
from subscription inner join plans
on subscription.plan_id = plans.plan_id
where plans.plan_id = 0)

, Annual_CTE as
( SELECT customer_id, start_date as start_annual
FROM subscription s
INNER JOIN 
plans p 
ON s.plan_id = p.plan_id
WHERE plan_name = 'pro annual')

select AVG(DATEDIFF(DAY, start_date, start_annual)) as avg_Day from 
 ANNUAL_CTE C2
LEFT JOIN Actual_CTE C1 ON C2.customer_id =C1.customer_id;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

