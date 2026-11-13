-- Consolidates item-level revenue and captured payments so marts use one consistent revenue definition.
with item_revenue as (
    select
        order_id,
        sum(line_total) as item_gross_revenue,
        sum(quantity) as units_sold
    from {{ ref('stg_order_items') }}
    group by order_id
),
payment_revenue as (
    select
        order_id,
        sum(case when payment_status = 'captured' then amount else 0 end) as captured_revenue,
        sum(case when payment_status = 'failed' then 1 else 0 end) as failed_payment_count,
        count(*) as payment_attempt_count
    from {{ ref('stg_payments') }}
    group by order_id
)
select
    o.order_id,
    o.customer_id,
    o.campaign_id,
    o.order_status,
    o.order_date,
    coalesce(i.item_gross_revenue, o.order_total) as gross_revenue,
    coalesce(p.captured_revenue, 0) as captured_revenue,
    coalesce(i.units_sold, 0) as units_sold,
    coalesce(p.failed_payment_count, 0) as failed_payment_count,
    coalesce(p.payment_attempt_count, 0) as payment_attempt_count
from {{ ref('stg_orders') }} o
left join item_revenue i on o.order_id = i.order_id
left join payment_revenue p on o.order_id = p.order_id
