select
    order_key,
    customer_key,
    total_price
from {{ ref('stg_tpch_orders') }}
where order_key <= 0
    or customer_key <= 0
    or total_price <= 0
