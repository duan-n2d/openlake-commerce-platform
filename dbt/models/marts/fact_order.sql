select
    order_id,
    customer_id,
    campaign_id,
    order_status,
    order_date,
    gross_revenue,
    captured_revenue,
    units_sold,
    failed_payment_count,
    payment_attempt_count
from {{ ref('int_order_revenue') }}
