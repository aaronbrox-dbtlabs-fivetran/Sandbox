with part_suppliers as (

    select * from {{ ref('stg_tpch_part_suppliers') }}

),

parts as (

    select * from {{ ref('stg_tpch_parts') }}

),

suppliers as (

    select * from {{ ref('stg_tpch_suppliers') }}

),

enriched_part_suppliers as (

    select
        part_suppliers.part_key,
        part_suppliers.supplier_key,
        parts.part_name,
        parts.manufacturer,
        parts.brand,
        parts.part_type,
        parts.part_size,
        parts.container,
        parts.retail_price,
        part_suppliers.available_quantity,
        part_suppliers.supply_cost,
        suppliers.supplier_name,
        suppliers.supplier_address,
        suppliers.nation_key,
        suppliers.phone_number,
        suppliers.account_balance,
        part_suppliers.comment as part_supplier_comment,
        parts.comment as part_comment,
        suppliers.comment as supplier_comment
    from part_suppliers
    inner join parts
        on part_suppliers.part_key = parts.part_key
    inner join suppliers
        on part_suppliers.supplier_key = suppliers.supplier_key

)

select * from enriched_part_suppliers
