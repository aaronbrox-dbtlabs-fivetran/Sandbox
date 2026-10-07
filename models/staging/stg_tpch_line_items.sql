select * from {{ source("tpch_now", "lineitem")}}
