{% macro classify_row_data_quality(trip_distance, total_amount, pickup_datetime, dropoff_datetime) %}
    -- A row is invalid when any data-quality rule fails.
    -- Explicit null checks ensure the result is always true or false.
    case
        when {{ trip_distance }} is null
          or {{ trip_distance }} < 0
          or {{ total_amount }} is null
          or {{ total_amount }} <= 0
          -- Compare timestamps directly to detect even sub-second negative durations.
          or {{ dropoff_datetime }} < {{ pickup_datetime }}
            then false
        else true
    end
{% endmacro %}
