select
    shipment_id,
    order_id,
    carrier,
    tracking_number,
    shipment_status,
    shipped_at,
    estimated_delivery_at,
    delivered_at,
    case
        when shipment_status = 'delayed' then true
        when delivered_at is null and estimated_delivery_at < current_timestamp then true
        else false
    end as is_delayed
from {{ ref('stg_shipments') }}
