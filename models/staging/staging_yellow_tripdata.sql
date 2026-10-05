{{ config({"materialized": "table"}) }}

select
    VendorID as vendor_id,
    tpep_pickup_datetime as pickup_datetime,
    tpep_dropoff_datetime as dropoff_datetime,
    passenger_count,
    trip_distance,
    RatecodeID as rate_code_id,
    PULocationID as pickup_location_id,
    DOLocationID as dropoff_location_id,
    payment_type,
    fare_amount,
    tip_amount,
    total_amount,

    -- Calculate trip duration in minutes using second-level precision
    -- to preserve valid trips shorter than one minute
    datediff(
        'second',
        tpep_pickup_datetime,
        tpep_dropoff_datetime
    ) / 60.0 as trip_duration_minutes,

    -- Preserve timestamp anomalies for monitoring and the bonus data-quality mart
    case
        when tpep_dropoff_datetime < tpep_pickup_datetime
            then 'negative_duration'
        when tpep_dropoff_datetime = tpep_pickup_datetime
            then 'zero_duration'
        else 'valid'
    end as duration_quality_status,

    -- Payment type 2 identifies prepaid trips
    case
        when payment_type = 2 then true
        else false
    end as is_prepaid,

    -- Distance classification comes from a reusable dbt macro
    {{ classify_distance('trip_distance') }} as distance_category

from {{ source('nyc_taxi', 'yellow_tripdata') }}

where trip_distance >= 0
  and total_amount > 0
