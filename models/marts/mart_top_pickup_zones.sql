{{ config(materialized='table') }}

with zone_totals as (
    select
        pickup_location_id,
        count(*) as total_trips,
        sum(total_amount) as total_revenue
    from {{ ref('staging_yellow_tripdata') }}
    group by pickup_location_id
),

ranked_zones as (
    select
        *,
        -- Location ID breaks ties so each ranking selects exactly five zones.
        row_number() over (
            order by total_trips desc, pickup_location_id
        ) as trip_count_rank,
        row_number() over (
            order by total_revenue desc, pickup_location_id
        ) as revenue_rank
    from zone_totals
)

select
    pickup_location_id,
    total_trips,
    round(total_revenue, 2) as total_revenue,
    trip_count_rank,
    revenue_rank
from ranked_zones
where trip_count_rank <= 5 or revenue_rank <= 5
order by trip_count_rank
