select
    payment_id,
    order_id,
    payment_method,
    payment_status,
    amount,
    failure_reason,
    processed_at
from {{ ref('stg_payments') }}
