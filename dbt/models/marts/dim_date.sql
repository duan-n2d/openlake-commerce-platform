with dates as (
    select cast(date_add('day', n, date '2026-01-01') as date) as date_day
    from unnest(sequence(0, 1095)) as t(n)
)
select
    date_day,
    year(date_day) as year,
    quarter(date_day) as quarter,
    month(date_day) as month,
    day(date_day) as day_of_month,
    day_of_week(date_day) as day_of_week
from dates
