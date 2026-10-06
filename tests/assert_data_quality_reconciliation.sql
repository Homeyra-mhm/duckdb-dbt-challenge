-- Every invalid raw record must be represented in the quality mart.
with raw_totals as (
    select
        count(*) as affected_rows,
        coalesce(sum(total_amount), 0) as affected_revenue
    from {{ ref('staging_yellow_raw_tripdata') }}
    where is_valid = false
),

mart_totals as (
    select
        coalesce(sum(affected_rows), 0) as affected_rows,
        coalesce(sum(affected_revenue), 0) as affected_revenue
    from {{ ref('mart_data_quality') }}
)

select
    r.affected_rows as raw_affected_rows,
    m.affected_rows as mart_affected_rows,
    r.affected_revenue as raw_affected_revenue,
    m.affected_revenue as mart_affected_revenue
from raw_totals r
cross join mart_totals m
where r.affected_rows <> m.affected_rows
   or abs(r.affected_revenue - m.affected_revenue) > 0.01
