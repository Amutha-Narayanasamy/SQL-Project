-- Total Number of Orders placed in Olist : 96470

select 
	count(*) as Num_order
From olist_orders_dataset
where order_status <> 'Canceled'
and order_delivered_customer_date is Not Null

-- Total Number of Customers : 99441
Select count(Distinct customer_Id) as Num_customers
from olist_orders_dataset

-- Total number of Products in Olist Store : 73
select count(Distinct product_category_name) as Num_products
from olist_products_dataset

select payment_type, round(sum(payment_value), 0) as Total_rev, count(order_id) as Num_order
from olist_order_payments_dataset
group by payment_type
order by Total_rev desc

-- Top 5 Products
select top 5 Year(order_purchase_timestamp) as Year,product_category_name_english as Product_name ,count(ooi.order_id) as Num_orders,
	rank() over(order by count(ooi.order_id) desc) as Rank
from olist_order_items_dataset ooi
join olist_orders_dataset ood
on ooi.order_id=ood.order_id
join products_category_with_eng_name pc
on ooi.product_id = pc.product_id
where order_status <> 'Canceled'
and order_delivered_customer_date is Not Null
group by product_category_name_english,Year(order_purchase_timestamp)
order by count(ooi.order_id) desc






-- Total Revenue Genetared by Olist Store from year 2016-2018 : $15,421,083
select round(sum(payment_value), 0) as Total_revenue
from olist_orders_dataset ood
join olist_order_payments_dataset oop
on ood.order_id=oop.order_id
where ood.order_status<>'Canceled' 
and ood.order_delivered_customer_date is not null

-- Number of orders placed over years
select year(order_delivered_customer_date) as Year, count(order_id) as Num_order
from olist_orders_dataset
where order_delivered_customer_date is not null
group by year(order_delivered_customer_date)

-- Yearly Sales
select year(order_delivered_customer_date) as Year, round(sum(payment_value), 0) as Total_revenue
from olist_orders_dataset ood
join olist_order_payments_dataset oop
on ood.order_id=oop.order_id
where ood.order_status<>'Canceled' 
and ood.order_delivered_customer_date is not null
group by year(order_delivered_customer_date)

-- Quarterly Sales
select year(order_delivered_customer_date) as Year, 
		datepart(quarter, order_delivered_customer_date) as Quarter,
		round(sum(payment_value), 0) as Total_revenue
from olist_orders_dataset ood
join olist_order_payments_dataset oop
on ood.order_id=oop.order_id
where ood.order_status<>'Canceled' 
and ood.order_delivered_customer_date is not null
group by year(order_delivered_customer_date),
		datepart(quarter,order_delivered_customer_date)
order by Year, Quarter


-- Monthly Sales
select year(order_delivered_customer_date) as Year, 
		datepart(quarter, order_delivered_customer_date) as Quarter,
		Month(order_delivered_customer_date) as Month,
		round(sum(payment_value), 0) as Total_revenue
from olist_orders_dataset ood
join olist_order_payments_dataset oop
on ood.order_id=oop.order_id
where ood.order_status<>'Canceled' 
and ood.order_delivered_customer_date is not null
group by year(order_delivered_customer_date),
		datepart(quarter,order_delivered_customer_date),
		Month(order_delivered_customer_date)
order by Total_revenue 

-- Delivery Status for orders
select count(order_id) as Num_order, case when order_delivered_customer_date >= order_estimated_delivery_date then 'late_delivery'
										 when order_delivered_customer_date <= order_estimated_delivery_date then 'ontime_delivery' else 'unknown' 
										 end as Delivery_status
from olist_orders_dataset
where order_status <> 'canceled'
and order_delivered_customer_date is not null
group by case when order_delivered_customer_date >= order_estimated_delivery_date then 'late_delivery'
			 when order_delivered_customer_date <= order_estimated_delivery_date then 'ontime_delivery' else 'unknown' end 


-- Number of Return Customers - 2801
select count(*) as num_return_customers
from 
(select oc.customer_unique_id as return_customer, count(distinct ood.order_id) as num_return_customer
		from olist_orders_dataset ood
		join olist_customers_dataset oc
		on ood.customer_id= oc.customer_id
		where ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null
		group by oc.customer_unique_id
		having count(ood.order_id)>1)
		--order by count(distinct ood.order_id) desc) 
		as return_customers;


-- Revenue from return customers : $864,357
select round(sum(Total_revenue), 0) as Rev_return_customers
from(
select oc.customer_unique_id as return_customer, 
		count(distinct ood.order_id) as num_return_customer, 
		sum(payment_value) as Total_revenue
		from olist_orders_dataset ood
		join olist_customers_dataset oc
		on ood.customer_id= oc.customer_id
		join olist_order_payments_dataset oop
		on ood.order_id = oop.order_id
		where oc.customer_unique_id in
		(select oc.customer_unique_id
		from olist_orders_dataset ood
		join olist_customers_dataset oc
		on ood.customer_id = oc.customer_id 
		where ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null
		group by oc.customer_unique_id
		having count(ood.order_id)>1)
		and ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null
		--order by count(distinct ood.order_id) desc) 
		group by oc.customer_unique_id 
		having count(ood.order_id) <> 1 ) as sub
		--order by count(distinct ood.order_id);

-- Customer Review Score
select review_score,count(order_id) as Num_orders
from olist_order_reviews_dataset
group by review_score
order by count(order_id)


-- Review Score based on avg_delivery_time
select  avg(Datediff(Day,ood.order_approved_at ,ood.order_delivered_customer_date)) as Avg_delivery_time, review_score 
from olist_orders_dataset ood
join olist_order_reviews_dataset oor
on ood.order_id= oor.order_id
where ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null and ood.order_approved_at is not null
group by review_score
order by review_score 

-- Top 10 cities with late deliveries and Review Score
select top 10 customer_city,avg(Datediff(Day,ood.order_approved_at ,ood.order_delivered_customer_date)) as Avg_delivery_time, review_score,case when order_delivered_customer_date >= order_estimated_delivery_date then 'late_delivery'
										 when order_delivered_customer_date <= order_estimated_delivery_date then 'ontime_delivery' else 'unknown' 
										 end as Delivery_status 
from olist_orders_dataset ood
join olist_order_reviews_dataset oor
on ood.order_id= oor.order_id
join olist_customers_dataset ocd
on ood.customer_id= ocd.customer_id
where ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null and ood.order_approved_at is not null
group by customer_city,review_score, case when order_delivered_customer_date >= order_estimated_delivery_date then 'late_delivery'
										 when order_delivered_customer_date <= order_estimated_delivery_date then 'ontime_delivery' else 'unknown' 
										 end
having avg(Datediff(Day,ood.order_approved_at ,ood.order_delivered_customer_date)) > (select avg(Datediff(Day,ood.order_approved_at ,ood.order_delivered_customer_date))
																						from olist_orders_dataset ood
																						where ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null and ood.order_approved_at is not null)
order by review_score



select top 10 customer_city,avg(Datediff(Day,ood.order_approved_at ,ood.order_delivered_customer_date)) as Avg_delivery_time, avg(Datediff(Day,ood.order_approved_at ,ood.order_estimated_delivery_date)) as Avg_estimated_delivery_time, review_score 
from olist_orders_dataset ood
join olist_order_reviews_dataset oor
on ood.order_id= oor.order_id
join olist_customers_dataset ocd
on ood.customer_id= ocd.customer_id
where ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null and ood.order_approved_at is not null
group by customer_city,review_score
having avg(Datediff(Day,ood.order_approved_at ,ood.order_delivered_customer_date)) > (select avg(Datediff(Day,ood.order_approved_at ,ood.order_delivered_customer_date))
																						from olist_orders_dataset ood
																						where ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null and ood.order_approved_at is not null)
order by review_score DESC

-- Top 10 cities Customer Recived the order later than expected average estimated delivery time and thier review score
select top 10 customer_city,avg(Datediff(Day,ood.order_approved_at ,ood.order_delivered_customer_date)) as Avg_delivery_time, avg(Datediff(Day,ood.order_approved_at ,ood.order_estimated_delivery_date)) as Avg_estimated_delivery_time, review_score 
from olist_orders_dataset ood
join olist_order_reviews_dataset oor
on ood.order_id= oor.order_id
join olist_customers_dataset ocd
on ood.customer_id= ocd.customer_id
where ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null and ood.order_approved_at is not null
group by customer_city,review_score
having avg(Datediff(Day,ood.order_approved_at ,ood.order_delivered_customer_date)) > (select avg(Datediff(Day,ood.order_approved_at ,ood.order_estimated_delivery_date))
																						from olist_orders_dataset ood
																						where ood.order_status<>'Canceled' 
		and ood.order_delivered_customer_date is not null and ood.order_approved_at is not null)
order by review_score 