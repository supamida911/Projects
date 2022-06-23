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