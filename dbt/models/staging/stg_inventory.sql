select
    cast(inventory_id as varchar) as inventory_id,
    cast(product_id as varchar) as product_id,
    warehouse_code,
    quantity_on_hand,
    reorder_threshold,
    updated_at
from {{ source('silver', 'inventory') }}
