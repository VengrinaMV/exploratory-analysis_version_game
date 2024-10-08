--запрос 1
select *
from registrations 

--запрос 2
select *
from purchases 

--запрос 3
select *
from products  

--запрос 4
select *
from logins 

--запрос 5
select max(price::int),
       min(price::int),
       avg(price::int),
       percentile_disc(0.5) within group (order by price::int) as median,
       percentile_disc(0.75) within group (order by price::int) as q75,
       percentile_disc(0.9) within group (order by price::int) as q9,
       percentile_disc(0.95) within group (order by price::int) as q95,
       percentile_disc(0.99) within group (order by price::int) as q99
 from products

 
--запрос 6 - определение arpu
select l.version
	,count(distinct l.user_id) as count_user
    ,avg(p.value) as avg_price
	,sum(p.value ) as sum_price
	,sum(p.value )/ count(distinct l.user_id) as ARPU
from registrations  as r
join logins   as l on r.user_id =l.user_id 
left join purchases as p on r.user_id =p.user_id 
join products  as p2 on p.product_id=p2.product_id 
where r.player_install_source = 'organic' and (l.version='1.2' or l.version='1.1')
group by  l.version

--запрос 7 --сравление PU
WITH us_by_group AS (   
    SELECT l.version,
           l.user_id,
           COUNT(p.value) AS purchase_count
    FROM registrations AS r
    JOIN logins AS l ON r.user_id = l.user_id 
    LEFT JOIN purchases AS p ON r.user_id = p.user_id 
    WHERE r.player_install_source = 'organic' 
      AND (l.version = '1.2' OR l.version = '1.1')
    GROUP BY l.version, l.user_id
),
t1 AS (
    SELECT version,
           COUNT(DISTINCT user_id) AS us_all
    FROM us_by_group
    GROUP BY version
),
t2 AS (
    SELECT version,
           COUNT(DISTINCT user_id) AS us_paid
    FROM us_by_group
    WHERE purchase_count > 0
    GROUP BY version
),
t3 AS (
    SELECT t1.version,
           us_all,
           COALESCE(t2.us_paid, 0) AS us_paid
    FROM t1
    LEFT JOIN t2 ON t1.version = t2.version
)
SELECT version,
       us_paid * 100.0 / NULLIF(us_all, 0) AS PU
FROM t3; 

--запрос 8
WITH category_revenue AS (
    SELECT t3.version,
        category,
        SUM(t1.value) AS category_total
    FROM 
        purchases t1
    JOIN 
        products t2 ON t1.product_id = t2.product_id 
    JOIN 
        logins t3 ON t1.user_id = t3.user_id 
    WHERE 
        t3.version IN ('1.1', '1.2')
    GROUP BY 
        category,t3.version
),
total_revenue AS (
    SELECT 
        SUM(category_total) AS total
    FROM 
        category_revenue
)
SELECT 
	cr.version,
    cr.category,
    cr.category_total,
    (cr.category_total / tr.total) * 100 AS revenue_share
FROM 
    category_revenue cr,
    total_revenue tr
ORDER BY 
    2;

