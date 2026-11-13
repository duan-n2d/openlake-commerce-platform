select
    cast(item_id as varchar) as item_id,
    cast(order_id as varchar) as order_id,
    cast(product_id as varchar) as product_id,
    quantity,
    cast(unit_price as decimal(12, 2)) as unit_price,
    cast(discount_amount as decimal(12, 2)) as discount_amount,
    cast(line_total as decimal(12, 2)) as line_total
from {{ source('silver', 'order_items') }}
