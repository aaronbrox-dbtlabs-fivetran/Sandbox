with orders as (
    select * from {{ ref('stg_jaffle_shop__orders') }}
)

, payments as (
    select * from {{ ref('stg_stripe__payments') }}
)

, order_payments as (
    select sum(payment_amount) as order_total
        , order_id
    from payments
    where payment_status = 'success'
    group by order_id
),

order_fact as (
    select orders.order_id
        , orders.customer_id
        , order_payments.order_total as amount 
    from orders
    join order_payments 
        on orders.order_id = order_payments.order_id
    order by orders.customer_id, orders.order_id
)

select * from order_fact