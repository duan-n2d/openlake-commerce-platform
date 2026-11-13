select
    p.sku,
    p.product_name,
    p.category,
    i.warehouse_code,
    i.quantity_on_hand,
    i.reorder_threshold,
    case
        when i.quantity_on_hand = 0 then 'critical'
        when i.quantity_on_hand <= i.reorder_threshold then 'reorder'
        when i.quantity_on_hand <= i.reorder_threshold * 2 then 'watch'
        else 'healthy'
    end as risk_level,
    i.updated_at
from {{ ref('stg_inventory') }} i
join {{ ref('dim_product') }} p on i.product_id = p.product_id
