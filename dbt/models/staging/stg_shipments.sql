select
    cast(shipment_id as varchar) as shipment_id,
    cast(order_id as varchar) as order_id,
    carrier,
    tracking_number,
    shipment_status,
    shipped_at,
    estimated_delivery_at,
    delivered_at,
    updated_at
from {{ source('silver', 'shipments') }}
