select
    order_date,
    count(distinct order_id) as order_count,
    sum(gross_revenue) as gross_revenue,
    sum(captured_revenue) as captured_revenue,
    sum(units_sold) as units_sold,
    sum(failed_payment_count) as failed_payment_count
from {{ ref('fact_order') }}
group by order_date
