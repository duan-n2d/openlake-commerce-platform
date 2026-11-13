select
    cast(event_id as varchar) as event_id,
    cast(session_id as varchar) as session_id,
    cast(customer_id as varchar) as customer_id,
    cast(campaign_id as varchar) as campaign_id,
    cast(product_id as varchar) as product_id,
    event_type,
    page_url,
    user_agent,
    occurred_at,
    cast(date(occurred_at) as date) as event_date
from {{ source('silver', 'clickstream_events') }}
