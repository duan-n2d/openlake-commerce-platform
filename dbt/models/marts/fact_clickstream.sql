select
    event_id,
    session_id,
    customer_id,
    campaign_id,
    product_id,
    event_type,
    page_url,
    occurred_at,
    event_date
from {{ ref('stg_clickstream_events') }}
