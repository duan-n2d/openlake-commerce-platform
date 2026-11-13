select
    cast(order_id as varchar) as order_id,
    cast(customer_id as varchar) as customer_id,
    cast(campaign_id as varchar) as campaign_id,
    order_status,
    cast(order_total as decimal(12, 2)) as order_total,
    currency,
    ordered_at,
    cast(date(ordered_at) as date) as order_date,
    updated_at
from {{ source('silver', 'orders') }}
