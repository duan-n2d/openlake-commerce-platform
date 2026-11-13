with sessions as (
    select
        campaign_id,
        count(distinct session_id) as sessions,
        sum(case when event_type = 'purchase' then 1 else 0 end) as conversions
    from {{ ref('fact_clickstream') }}
    where campaign_id is not null
    group by campaign_id
),
revenue as (
    select
        campaign_id,
        sum(captured_revenue) as attributed_revenue
    from {{ ref('fact_order') }}
    where campaign_id is not null
    group by campaign_id
)
select
    c.campaign_id,
    c.campaign_code,
    c.channel,
    c.campaign_name,
    coalesce(s.sessions, 0) as sessions,
    coalesce(s.conversions, 0) as conversions,
    cast(coalesce(s.conversions, 0) as double) / nullif(s.sessions, 0) as conversion_rate,
    coalesce(r.attributed_revenue, 0) as attributed_revenue
from {{ ref('dim_campaign') }} c
left join sessions s on c.campaign_id = s.campaign_id
left join revenue r on c.campaign_id = r.campaign_id
