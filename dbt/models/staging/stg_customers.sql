select
    cast(customer_id as varchar) as customer_id,
    lower(email) as email,
    concat(first_name, ' ', last_name) as full_name,
    loyalty_tier,
    marketing_opt_in,
    city,
    state,
    country,
    created_at,
    updated_at
from {{ source('silver', 'customers') }}
