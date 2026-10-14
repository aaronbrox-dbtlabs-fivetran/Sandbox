select 
    payment_id as id,
    order_id as orderid,
    payment_method as paymentmethod,
    payment_status as paymentstatus,

    -- amount is stored in cents, convert it to dollars
    {{ cents_to_dollars("payment_amount") }} as amount,
    payment_created as created_at
from {{ ref('stg_stripe__payments') }}

-- select *
-- from {{ ref('stg_stripe__payments') }}
