{{ config(materialized='table') }}

select
    distance_category,
    count(*) as total_trips,
    round(avg(trip_duration_minutes), 2) as avg_trip_duration_minutes,
    round(sum(total_amount), 2) as total_revenue

from {{ ref('staging_yellow_tripdata') }}

group by distance_category

order by
    case distance_category
        when 'short' then 1
        when 'medium' then 2
        when 'long' then 3
    end
