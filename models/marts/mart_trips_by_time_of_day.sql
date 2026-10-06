{{ config(materialized='table') }}

select
    time_of_day,

    count(*) as total_trips,
    -- Round aggregated revenue to two decimal places.
    round(sum(total_amount), 2) as total_revenue

from {{ ref('staging_yellow_tripdata') }}

group by time_of_day
