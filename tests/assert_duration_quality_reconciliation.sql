-- Every retained duration anomaly must be represented in the quality mart.
with staging_totals as (
    select
        count(*) as affected_rows
    from {{ ref('staging_yellow_tripdata') }}
    where duration_quality_status <> 'valid'
),

mart_totals as (
    select
        coalesce(sum(affected_rows), 0) as affected_rows
    from {{ ref('mart_duration_data_quality') }}
)

select
    s.affected_rows as staging_affected_rows,
    m.affected_rows as mart_affected_rows
from staging_totals s
cross join mart_totals m
where s.affected_rows <> m.affected_rows