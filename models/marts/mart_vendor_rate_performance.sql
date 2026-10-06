{{ config(materialized='table') }}

select
    vendor_id,

    round(
        avg(tip_amount / total_amount) * 100,
        2
    ) as avg_tip_percentage

from {{ ref('staging_yellow_tripdata') }}

group by vendor_id
order by vendor_id
