select
    c.customer_id,
    c.email,
    c.full_name,
    c.loyalty_tier,
    c.city,
    c.state,
    count(distinct o.order_id) as lifetime_orders,
    coalesce(sum(o.captured_revenue), 0) as lifetime_revenue,
    max(o.order_date) as last_order_date,
    count(distinct cs.session_id) as known_sessions,
    max(cs.occurred_at) as last_activity_at
from {{ ref('dim_customer') }} c
left join {{ ref('fact_order') }} o on c.customer_id = o.customer_id
left join {{ ref('fact_clickstream') }} cs on c.customer_id = cs.customer_id
group by 1, 2, 3, 4, 5, 6
