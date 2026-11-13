select
    product_id,
    sku,
    product_name,
    category,
    brand,
    unit_price,
    active
from {{ ref('stg_products') }}
