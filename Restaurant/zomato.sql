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

# 매장별 가격
select `restaurant name`,
	city,
    `average cost for two`,
    row_number() over(order by `average cost for two` desc) as cost_rnk
from zomato;

# 업종별 평균 평점, 가격
select cuisines,
	avg(`average cost for two`) as avg_cost
from zomato
group by 1;