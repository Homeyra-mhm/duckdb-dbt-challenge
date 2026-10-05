{{ config({"materialized": "table"}) }}

select
    duration_quality_status as issue_type,
    -- Percentage among anomalous records, not among all staging records.
    count(*) as affected_rows,
    round(
        100.0 * count(*) / sum(count(*)) over (),
        2
    ) as affected_rows_pct,
    round(sum(total_amount), 2) as affected_revenue,
    round(avg(total_amount), 2) as avg_total_amount,
    round(avg(trip_distance), 2) as avg_trip_distance,
    round(max(trip_distance), 2) as max_trip_distance

from {{ ref('staging_yellow_tripdata') }}

where duration_quality_status <> 'valid'

group by duration_quality_status

order by affected_rows desc