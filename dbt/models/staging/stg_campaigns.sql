select
    cast(campaign_id as varchar) as campaign_id,
    campaign_code,
    campaign_name,
    channel,
    start_date,
    end_date,
    cast(budget_amount as decimal(12, 2)) as budget_amount
from {{ source('silver', 'campaigns') }}
