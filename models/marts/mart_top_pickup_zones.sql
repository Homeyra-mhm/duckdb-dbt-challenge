{{ config({"materialized": "table"}) }}

select
    pickup_location_id,
    count(*) as total_trips,
    round(sum(total_amount), 2) as total_revenue

from {{ ref('staging_yellow_tripdata') }}

group by pickup_location_id

order by total_trips desc

limit 5