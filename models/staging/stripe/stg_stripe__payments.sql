select 
    r.id as customer_id
    , r.orderid as order_id
    , r.paymentmethod
    , r.status 
    , r.amount 
    , r.created 
    , r._batched_at


from raw.stripe.payment as r 