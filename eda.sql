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

--запрос 6 - определение arpdau
select round(sum(rev) / (
                    select count(distinct tt2.user_id) as users
                    from game.logins as tt2
                        join(
                             select user_id
                             from game.registrations
                             where player_install_source = 'organic'
                            ) as tt1 on tt1.user_id = tt2.user_id 
                    where version in ('1.1')
                   ), 2) as ARPDAU
    ,  version
from(
    select sum(value) as rev
        ,  t2.user_id
        ,  version
    from game.purchases as t2
        join(
                select min(time) as min_time
                    ,  max(time) as max_time
                    ,  t1.user_id 
                    ,  version
                from game.logins as t1
                    join(
                         select user_id
                         from game.registrations
                         where player_install_source = 'organic'
                        ) as t4 on t1.user_id = t4.user_id 
                where version in ('1.1')
                group by version, t1.user_id
                ) as t1 on t1.user_id = t2.user_id
    where time between min_time and max_time
    group by t2.user_id, version
    ) as t3
group by version
union all 
select round(sum(rev) / (
                    select count(distinct tt2.user_id) as users
                    from game.logins as tt2
                        join(
                             select user_id
                             from game.registrations
                             where player_install_source = 'organic'
                            ) as tt1 on tt1.user_id = tt2.user_id 
                    where version in ('1.2')
                   ), 2) as ARPDAU
    ,  version
from(
    select sum(value) as rev
        ,  t2.user_id
        ,  version
    from game.purchases as t2
        join(
                select min(time) as min_time
                    ,  max(time) as max_time
                    ,  t1.user_id 
                    ,  version
                from game.logins as t1
                    join(
                         select user_id
                         from game.registrations
                         where player_install_source = 'organic'
                        ) as t4 on t1.user_id = t4.user_id 
                where version in ('1.2')
                group by version, t1.user_id
            ) as t1 on t1.user_id = t2.user_id
    where time between min_time and max_time
    group by t2.user_id, version
    ) as t3
group by version

--запрос 7 --сравнение PU
select count(distinct user_id)::DOUBLE precision / 
                         (
                        select count(distinct tt2.user_id)
                        from game.logins as tt2
                            join(
                                 select distinct user_id
                                 from game.registrations
                                 where player_install_source = 'organic'
                                ) as tt1 on tt1.user_id = tt2.user_id 
                        where version in ('1.1')
                       )*100 as pu                      
        ,  version
    from(
        select distinct t2.user_id
            ,  version
        from game.purchases as t2
            join(
                    select min(time) as min_time
                        ,  max(time) as max_time
                        ,  t1.user_id 
                        ,  version
                    from game.logins as t1
                        join(
                             select user_id
                             from game.registrations
                             where player_install_source = 'organic'
                            ) as t4 on t1.user_id = t4.user_id 
                    where version in ('1.1')
                    group by version, t1.user_id
                ) as t1 on t1.user_id = t2.user_id
        where time between min_time and max_time
        group by t2.user_id, version
        ) as t3
group by version 
union all 
select count(distinct user_id)::DOUBLE precision / 
                         (
                        select count(distinct tt2.user_id)
                        from game.logins as tt2
                            join(
                                 select distinct user_id
                                 from game.registrations
                                 where player_install_source = 'organic'
                                ) as tt1 on tt1.user_id = tt2.user_id 
                        where version in ('1.2')
                       )*100 as pu                  
        ,  version
    from(
        select distinct t2.user_id
            ,  version
        from game.purchases as t2
            join(
                    select min(time) as min_time
                        ,  max(time) as max_time
                        ,  t1.user_id 
                        ,  version
                    from game.logins as t1
                        join(
                             select user_id
                             from game.registrations
                             where player_install_source = 'organic'
                            ) as t4 on t1.user_id = t4.user_id 
                    where version in ('1.2')
                    group by version, t1.user_id
        
                ) as t1 on t1.user_id = t2.user_id
        
        where time between min_time and max_time
        group by t2.user_id, version
        ) as t3
group by version


--запрос 8
with cte_table as(
select sum(rev) as revenue
    ,  count(*) as cnt
    ,  version
    ,  category
from(
    select sum(value) as rev
        ,  t2.user_id
        ,  product_id 
        ,  version
    from game.purchases as t2
        join(
                select min(time) as min_time
                    ,  max(time) as max_time
                    ,  t1.user_id 
                    ,  version
                from game.logins as t1
                    join(
                         select user_id
                         from game.registrations
                         where player_install_source = 'organic'
                        ) as t4 on t1.user_id = t4.user_id 
                where version in ('1.2')
                group by version, t1.user_id
            ) as t1 on t1.user_id = t2.user_id  
    where time between min_time and max_time
    group by t2.user_id, version, product_id
    ) as t7 join(
            select product_id
                ,  category
            from game.products
            ) as t6 on t7.product_id = t6.product_id
group by version, category
union all 
select sum(rev) as revenue
    ,  count(*) as cnt
    ,  version
    ,  category
from(
    select sum(value) as rev
        ,  t2.user_id
        ,  product_id 
        ,  version
    from game.purchases as t2
        join(
                select min(time) as min_time
                    ,  max(time) as max_time
                    ,  t1.user_id 
                    ,  version
                from game.logins as t1
                    join(
                         select user_id
                         from game.registrations
                         where player_install_source = 'organic'
                        ) as t4 on t1.user_id = t4.user_id 
                where version in ('1.1')
                group by version, t1.user_id
            ) as t1 on t1.user_id = t2.user_id
        where time between min_time and max_time
    group by t2.user_id, version, product_id
    ) as t7 join(
            select product_id
                ,  category
            from game.products
            ) as t6 on t7.product_id = t6.product_id
group by version, category)
select round(revenue / sum_rev, 2) as rev_share
    ,  round(cnt / sum_cnt, 2) as orders_count_share
    ,  ct.version 
    ,  category
from cte_table as ct
    join(
         select sum(revenue) as sum_rev    
             ,  sum(cnt) as sum_cnt
             ,  version
         from cte_table
         group by version
        ) as ct2 on ct.version = ct2.version
        order by 4 

   

