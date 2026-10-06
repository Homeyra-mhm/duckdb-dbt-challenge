{{ config(materialized='table') }}

with valid_records as (
    select *
    from {{ ref('staging_yellow_raw_tripdata') }}
    where is_valid = true
)

select
    vendor_id,
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    rate_code_id,
    pickup_location_id,
    dropoff_location_id,
    payment_type,
    fare_amount,
    tip_amount,
    total_amount,

    -- Preserve second-level precision for trips shorter than one minute.
    datediff('second', pickup_datetime, dropoff_datetime)
        / 60.0 as trip_duration_minutes,

    case when payment_type = 2 then true else false end as is_prepaid,
    {{ classify_distance('trip_distance') }} as distance_category,
    {{ classify_time_slots('pickup_datetime') }} as time_of_day,
    is_valid

from valid_records
