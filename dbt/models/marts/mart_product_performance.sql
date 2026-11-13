select
    p.product_id,
    p.sku,
    p.product_name,
    p.category,
    sum(oi.quantity) as units_sold,
    sum(oi.line_total) as gross_revenue
from {{ ref('stg_order_items') }} oi
join {{ ref('dim_product') }} p on oi.product_id = p.product_id
group by 1, 2, 3, 4
