# 데이터 살펴보기
select *
from olist.orders;

select count(*),
	count(distinct customer_id) as user_num
from olist.orders;
-- 한명의 고객이 한번의 주문을 함

-- 주문날짜 확인
select min(order_purchase_timestamp),
	max(order_purchase_timestamp)
from olist.orders;
-- 주문 상태의 종류 확인
select distinct order_status
from olist.orders;
-- unavailable, canceled 존재함

# 일자별, 주별, 월별 주문자 수
-- 일별
select substr(order_purchase_timestamp, 1, 10) as 'date',
	count(distinct customer_id) as user_cnt
from olist.orders
where order_status not in('unavailable', 'canceled')
group by 1;
-- 주별
select yearweek(order_purchase_timestamp) as 'week',
	count(distinct customer_id) as user_cnt
from olist.orders
where order_status not in('unavailable', 'canceled')
group by 1;
-- 월별
select substr(order_purchase_timestamp, 1, 7) as 'month',
	count(distinct customer_id) as user_cnt
from olist.orders
where order_status not in('unavailable', 'canceled')
group by 1;

# 지역별 일자별, 주별, 월별 주문자 수
-- 일자별
select substr(a.order_purchase_timestamp, 1, 10) as 'date',
	b.customer_state as 'state',
	count(distinct a.customer_id) as user_cnt
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
where order_status not in('unavailable', 'canceled')
group by 1, 2
order by 1;
-- 주차별
select yearweek(a.order_purchase_timestamp) as 'week',
	b.customer_state as 'state',
	count(distinct a.customer_id) as user_cnt
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
where order_status not in('unavailable', 'canceled')
group by 1, 2
order by 1;
-- 월별
select substr(a.order_purchase_timestamp, 1, 7) as 'month',
	b.customer_state as 'state',
	count(distinct a.customer_id) as user_cnt
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
where order_status not in('unavailable', 'canceled')
group by 1, 2
order by 1;

# 지역별 월별 매출 순위
with rev_rnk as
(select substr(a.order_purchase_timestamp, 1, 7) as YM,
	b.customer_state as 'state',
    count(distinct a.customer_id) as user_cnt,
    sum(c.payment_value) as 'rev',
    row_number() over(partition by substr(a.order_purchase_timestamp, 1, 7) order by sum(c.payment_value) desc) as rnk
from olist.orders as a
	left join olist.customers as b
		on a.customer_id= b.customer_id
	left join olist.payments as c
		on a.order_id= c.order_id
group by 1, 2
order by 1),
-- 위 테이블에서 월별 1위 지역만 추출
monthly_top as
(select ym,
	state
from rev_rnk
where rnk= 1)
-- 이 지역 유저들이 구매한 상품들 상위 5개
select c.product_category_name as 'product',
	count(distinct a.customer_id) as user_cnt
from olist.orders as a
	left join olist.order_items as b
		on a.order_id= b.order_id
	left join olist.products as c
		on b.product_id= c.product_id
where a.customer_id in (select customer_id
						from olist.customers
							where customer_state in (select state from monthly_top))
group by 1
order by 2 desc
limit 5;