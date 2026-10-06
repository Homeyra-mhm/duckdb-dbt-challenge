{{ config(materialized='table') }}

with standardized as (
    select
        cast(VendorID as bigint) as vendor_id,
        cast(tpep_pickup_datetime as timestamp) as pickup_datetime,
        cast(tpep_dropoff_datetime as timestamp) as dropoff_datetime,
        cast(passenger_count as bigint) as passenger_count,
        cast(trip_distance as double) as trip_distance,
        cast(RatecodeID as bigint) as rate_code_id,
        cast(store_and_fwd_flag as varchar) as store_and_fwd_flag,
        cast(PULocationID as bigint) as pickup_location_id,
        cast(DOLocationID as bigint) as dropoff_location_id,
        cast(payment_type as bigint) as payment_type,
        cast(fare_amount as double) as fare_amount,
        cast(extra as double) as extra,
        cast(mta_tax as double) as mta_tax,
        cast(tip_amount as double) as tip_amount,
        cast(tolls_amount as double) as tolls_amount,
        cast(improvement_surcharge as double) as improvement_surcharge,
        cast(total_amount as double) as total_amount,
        cast(congestion_surcharge as double) as congestion_surcharge,
        cast(Airport_fee as double) as airport_fee,
        cast(cbd_congestion_fee as double) as cbd_congestion_fee,
        cast(request_source as varchar) as request_source
    from {{ source('nyc_taxi', 'yellow_tripdata') }}
)

select
    *,
    {{ classify_row_data_quality(
        'trip_distance', 'total_amount', 'pickup_datetime', 'dropoff_datetime'
    ) }} as is_valid
from standardized
