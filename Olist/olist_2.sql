# 월별 매출 순위
select substr(a.order_purchase_timestamp, 1, 7) as YM,
	b.customer_state as 'state',
    sum(c.payment_value) as 'rev',
    dense_rank() over(partition by substr(a.order_purchase_timestamp, 1, 7) order by sum(c.payment_value) desc) as rnk
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
	left join olist.payments as c
		on a.order_id= c.order_id
where a.order_status not in ('unavailable', 'canceled')
group by 1, 2
order by 1;

# 지역별 월별 구매자 수 순위 (불가능, 취소 주문 제외)
select substr(a.order_purchase_timestamp, 1, 7) as YM,
	b.customer_state as 'state',
    count(distinct a.customer_id) as user_cnt,
    dense_rank() over(partition by substr(a.order_purchase_timestamp, 1, 7) order by count(distinct a.customer_id) desc) as rnk
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
	left join olist.payments as c
		on a.order_id= c.order_id
where a.order_status not in ('unavailable', 'canceled')
group by 1, 2
order by 1;

# 상품의 월별 주문량, 매출
select substr(a.order_purchase_timestamp, 1, 7) as YM,
	c.product_category_name as 'product',
    count(distinct a.customer_id) as user_cnt,
    sum(d.payment_value) as rev
from olist.orders as a
	left join olist.order_items as b
		on a.order_id= b.order_id
	left join olist.products as c
		on b.product_id= c.product_id
	left join olist.payments as d
		on a.order_id= d.order_id
where a.order_status not in ('unavailable', 'canceled')
group by 1, 2
order by 1;

# 상품의 월별 지역별 주문량, 매출
select d.product_category_name as 'product',
	substr(a.order_purchase_timestamp, 1, 7) as YM,
	b.customer_state as 'state',
    count(distinct a.customer_id) as user_cnt,
    sum(e.payment_value) as rev
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
	left join olist.order_items as c
		on a.order_id= c.order_id
	left join olist.products as d
		on c.product_id= d.product_id
	left join olist.payments as e
		on a.order_id= e.order_id
where a.order_status not in ('unavailable', 'canceled')
group by 1, 2, 3
order by 2;

select *
from olist.orders
where order_status not in ('unavailable', 'canceled');

select *
from olist.order_items;

select *
from olist.sellers;

# 어느 지역의 물품을 많이 구매할까?
-- 판매자의 월별 판매 순위 (구매자 기준)
with seller_monthly as
(select substr(a.order_purchase_timestamp, 1, 7) as YM,
	c.seller_id,
    count(distinct a.customer_id) as pu_cnt,
    dense_rank() over(partition by substr(a.order_purchase_timestamp, 1, 7) order by count(distinct a.customer_id) desc) as rnk
from olist.orders as a
	left join olist.order_items as b
		on a.order_id= b.order_id
	left join olist.sellers as c
		on b.seller_id= c.seller_id
where a.order_status not in ('unavailable', 'canceled')
group by 1, 2
order by 1),
-- 월별 판매량 1위 판매자
top_sellers as
(select ym,
	seller_id,
    pu_cnt
from seller_monthly
where rnk= 1)
-- 이 판매자들이 판매한 물품들?
select c.product_category_name as 'product',
	count(distinct a.customer_id) as pu_cnt
from olist.orders as a
	left join olist.order_items as b
		on a.order_id= b.order_id
	left join olist.products as c
		on b.product_id= c.product_id
where a.order_status not in ('unavailable', 'canceled')
	and b.seller_id in (select seller_id from top_sellers)
group by 1
order by 2 desc;

# 지역별 취소 주문 비율
-- 지역별 취소 주문량
with canceled as
(select b.customer_state as 'state',
	count(a.order_id) as order_cnt
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
where a.order_status= 'canceled'
group by 1),
-- 지역별 전체 주문량
total_orders as
(select b.customer_state as 'state',
	count(a.order_id) as order_cnt
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
where a.order_status!= 'unavailable'
group by 1)
-- 취소 주문 비율 계산
select a.state,
	a.order_cnt as 'total_orders',
    coalesce(b.order_cnt, 0) as 'canceled_orders',
    coalesce(b.order_cnt/ a.order_cnt* 100, 0) as ratio
from total_orders as a
	left join canceled as b
		on a.state= b.state;

# 물품별 취소 비율
-- 물품별 주문량
with total_order as
(select coalesce(c.product_category_name, 'unknown') as 'product',
	count(a.order_id) as order_cnt
from olist.orders as a
	left join olist.order_items as b
		on a.order_id= b.order_id
	left join olist.products as c
		on b.product_id= c.product_id
where a.order_status!= 'unavailale'
group by 1),
-- 물품별 취소 주문량
canceled as
(select coalesce(c.product_category_name, 'unknown') as 'product',
	count(a.order_id) as canceled_cnt
from olist.orders as a
	left join olist.order_items as b
		on a.order_id= b.order_id
	left join olist.products as c
		on b.product_id= c.product_id
where a.order_status= 'canceled'
group by 1)

select a.product,
	a.order_cnt as 'total_orders',
    coalesce(b.canceled_cnt, 0) as 'canceled_orders',
    coalesce(b.canceled_cnt/ a.order_cnt* 100, 0) as ratio
from total_order as a
	left join canceled as b
		on a.product= b.product;

# 월간 취소 주문량 추세
select substr(a.order_purchase_timestamp, 1, 7) as YM,
	count(a.order_id) as canceled_cnt
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
where order_status= 'canceled'
group by 1
order by 1;

# 매 월 가장 취소를 많이 한 지역
with top_canceled as
(select substr(a.order_purchase_timestamp, 1, 7) as YM,
	b.customer_state as 'state',
    count(a.order_id) as canceled_cnt,
    dense_rank() over(partition by substr(a.order_purchase_timestamp, 1, 7) order by count(a.order_id) desc) as rnk
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
where a.order_status= 'canceled'
group by 1, 2
order by 1)

select ym,
	state,
	canceled_cnt
from top_canceled
where rnk= 1;

# 매 월 지역별로 가장 많이 취소된 제품
with monthly_canceled as
(select substr(a.order_purchase_timestamp, 1, 7) as YM,
	b.customer_state as 'state',
    coalesce(d.product_category_name, 'unknown') as 'product',
    count(a.order_id) as canceled_cnt,
    dense_rank() over(partition by substr(a.order_purchase_timestamp, 1, 7) order by count(a.order_id) desc) as rnk
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
	left join olist.order_items as c
		on a.order_id= c.order_id
	left join olist.products as d
		on c.product_id= d.product_id
where a.order_status= 'canceled'
group by 1, 2
order by 1)

select ym, state, product, canceled_cnt
from monthly_canceled
where rnk= 1;