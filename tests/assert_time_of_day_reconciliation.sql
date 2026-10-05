-- All cleaned trips must be represented in the time-of-day mart.
-- Allow $0.03 for rounding across four revenue groups.
with staging_totals as (
    select
        count(*) as total_trips,
        coalesce(sum(total_amount), 0) as total_revenue
    from {{ ref('staging_yellow_tripdata') }}
),

mart_totals as (
    select
        coalesce(sum(total_trips), 0) as total_trips,
        coalesce(sum(total_revenue), 0) as total_revenue
    from {{ ref('mart_trips_by_time_of_day') }}
)

select
    s.total_trips as staging_trips,
    m.total_trips as mart_trips,
    s.total_revenue as staging_revenue,
    m.total_revenue as mart_revenue
from staging_totals s
cross join mart_totals m
where s.total_trips <> m.total_trips
   or abs(s.total_revenue - m.total_revenue) > 0.03