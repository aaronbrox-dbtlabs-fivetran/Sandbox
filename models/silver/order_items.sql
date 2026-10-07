with line_items as (

    select * from {{ ref('stg_tpch_line_items') }}

),

orders as (

    select * from {{ ref('stg_tpch_orders') }}

),

order_items as (

    select
        line_items.order_key,
        line_items.line_number,
        line_items.part_key,
        line_items.supplier_key,
        orders.customer_key,
        orders.order_status,
        orders.order_date,
        orders.order_time,
        orders.order_priority,
        orders.clerk,
        orders.shipping_priority,
        orders.total_price as order_total_price,
        line_items.quantity,
        line_items.extended_price,
        line_items.discount_rate,
        line_items.tax_rate,
        line_items.extended_price * line_items.discount_rate as discount_amount,
        line_items.extended_price * (1 - line_items.discount_rate) as net_item_amount,
        line_items.extended_price * (1 - line_items.discount_rate) * line_items.tax_rate as tax_amount,
        line_items.extended_price * (1 - line_items.discount_rate) * (1 + line_items.tax_rate) as total_item_amount,
        line_items.return_flag,
        line_items.line_status,
        line_items.ship_date,
        line_items.commit_date,
        line_items.receipt_date,
        line_items.shipping_instructions,
        line_items.shipping_mode,
        line_items.comment as line_item_comment,
        orders.comment as order_comment
    from line_items
    inner join orders
        on line_items.order_key = orders.order_key

)

select * from order_items
