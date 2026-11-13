select
    cast(payment_id as varchar) as payment_id,
    cast(order_id as varchar) as order_id,
    payment_method,
    payment_status,
    cast(amount as decimal(12, 2)) as amount,
    failure_reason,
    processed_at,
    updated_at
from {{ source('silver', 'payments') }}
