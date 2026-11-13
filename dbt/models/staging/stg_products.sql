select
    cast(product_id as varchar) as product_id,
    sku,
    product_name,
    category,
    brand,
    cast(unit_price as decimal(12, 2)) as unit_price,
    active
from {{ source('silver', 'products') }}
