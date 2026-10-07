with order_items as (

    select * from {{ ref('order_items') }}

),

part_suppliers as (

    select * from {{ ref('part_suppliers') }}

),

final as (

    select
        order_items.order_key || '-' || order_items.line_number as order_item_key,
        order_items.order_key,
        order_items.line_number,
        order_items.part_key,
        order_items.supplier_key,
        order_items.customer_key,
        order_items.order_status,
        order_items.order_date,
        order_items.order_time,
        order_items.order_priority,
        order_items.clerk,
        order_items.shipping_priority,
        order_items.quantity,
        order_items.extended_price,
        order_items.discount_rate,
        order_items.tax_rate,
        order_items.discount_amount,
        order_items.net_item_amount,
        order_items.tax_amount,
        order_items.total_item_amount,
        part_suppliers.supply_cost,
        order_items.quantity * part_suppliers.supply_cost as estimated_supply_cost,
        order_items.net_item_amount - (order_items.quantity * part_suppliers.supply_cost) as estimated_margin_amount,
        order_items.return_flag,
        order_items.line_status,
        order_items.ship_date,
        order_items.commit_date,
        order_items.receipt_date,
        order_items.shipping_instructions,
        order_items.shipping_mode,
        part_suppliers.part_name,
        part_suppliers.manufacturer,
        part_suppliers.brand,
        part_suppliers.part_type,
        part_suppliers.part_size,
        part_suppliers.container,
        part_suppliers.retail_price,
        part_suppliers.available_quantity,
        part_suppliers.supplier_name,
        part_suppliers.supplier_address,
        part_suppliers.nation_key,
        part_suppliers.phone_number,
        part_suppliers.account_balance,
        order_items.line_item_comment,
        order_items.order_comment,
        part_suppliers.part_supplier_comment,
        part_suppliers.part_comment,
        part_suppliers.supplier_comment
    from order_items
    left join part_suppliers
        on order_items.part_key = part_suppliers.part_key
        and order_items.supplier_key = part_suppliers.supplier_key

)

select * from final
