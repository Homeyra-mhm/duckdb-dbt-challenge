{{ config(materialized='table') }}

-- Monitor rejected records using the validity flag calculated in raw staging.
select
    false as is_valid,
    count(*) as affected_rows,
    round(
        100.0 * count(*) / nullif(
            (select count(*) from {{ ref('staging_yellow_raw_tripdata') }}),
            0
        ),
        2
    ) as affected_rows_pct,
    coalesce(round(sum(total_amount), 2), 0) as affected_revenue,
    round(avg(total_amount), 2) as avg_total_amount,
    round(avg(trip_distance), 2) as avg_trip_distance,
    round(max(trip_distance), 2) as max_trip_distance

from {{ ref('staging_yellow_raw_tripdata') }}
where is_valid = false
