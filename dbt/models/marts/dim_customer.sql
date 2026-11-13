select
    customer_id,
    email,
    full_name,
    loyalty_tier,
    marketing_opt_in,
    city,
    state,
    country,
    created_at,
    updated_at
from {{ ref('stg_customers') }}
