select
    campaign_id,
    campaign_code,
    campaign_name,
    channel,
    start_date,
    end_date,
    budget_amount
from {{ ref('stg_campaigns') }}
