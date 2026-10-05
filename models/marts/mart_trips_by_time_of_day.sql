{{ config({"materialized": "table"}) }}

select
    case
        when hour(pickup_datetime) >= 5
         and hour(pickup_datetime) < 12
            then 'morning'

        when hour(pickup_datetime) >= 12
         and hour(pickup_datetime) < 17
            then 'afternoon'

        when hour(pickup_datetime) >= 17
         and hour(pickup_datetime) < 22
            then 'evening'

        else 'night'
    end as time_of_day,

    count(*) as total_trips,
    -- Per un valore monetario è molto più leggibile:
    round(sum(total_amount), 2) as total_revenue

from {{ ref('staging_yellow_tripdata') }}

group by 1