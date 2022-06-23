use restaurant;
# 데이터 살펴보기
select count(*)
from zomato;

select *
from zomato;

-- Restaurant ID 칼럼 삭제
alter table zomato drop `Restaurant ID`;

select *
from zomato;

-- 평점 종류 확인
select `rating color`,
	count(`rating color`),
	`rating text`,
	count(`rating text`)
from zomato
group by 1, 3
order by 2 desc, 4 desc;

# 지역별 평균 평점
select city,
	avg(longitude) as 'longitude',
    avg(latitude) as 'latitude',
	avg(`aggregate rating`) as rating,
    row_number() over(order by avg(`aggregate rating`) desc) as rating_rnk
from zomato
group by 1;

# 매장별 평점
select `restaurant name`,
	city,
    `aggregate rating`,
    dense_rank() over(order by `aggregate rating` desc) as rating_rnk
from zomato;

# 매장별 평점, 2인 평균 가격
-- 통화 통일
with tmp as
(select `restaurant name`,
	city,
    cuisines,
    `aggregate rating`,
    case when currency like 'Botswana%' then `average cost for two`* 0.082
		when currency like 'Brazilian%' then `average cost for two`* 0.19
        when currency like 'Emirati%' then `average cost for two`* 0.27
        when currency like 'Indian%' then `average cost for two`* 0.013
        when currency like 'Indonesian%' then `average cost for two`* 0.000067
        when currency like 'NewZealand%' then `average cost for two`* 0.63
        when currency like 'Pounds%' then `average cost for two`* 1.23
        when currency like 'Qatari%' then `average cost for two`* 0.27
        when currency like 'Rand%' then `average cost for two`* 0.063
        when currency like 'Sri%' then `average cost for two`* 0.0028
        when currency like 'Turkish%' then `average cost for two`* 0.058
        else `average cost for two`
        end as 'cost'
from zomato)
select *
from tmp;

# 온라인 주문 가능 여부에 따른 평점
-- 온라인 주문이 가능한 식당의 개수
select `has online delivery`,
	count(`restaurant name`) as restaurant_cnt
from zomato
group by 1;
-- 가능 여부에 따른 평점
select `has online delivery` as 'Online_Delivery',
	avg(`aggregate rating`) as 'rating'
from zomato
group by 1;

select *
from zomato;