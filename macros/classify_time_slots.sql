{% macro classify_time_slots(datetime_column) %}
    case
        when hour({{ datetime_column }}) >= 5
         and hour({{ datetime_column }}) < 12 then 'morning'
        when hour({{ datetime_column }}) >= 12
         and hour({{ datetime_column }}) < 17 then 'afternoon'
        when hour({{ datetime_column }}) >= 17
         and hour({{ datetime_column }}) < 22 then 'evening'
        else 'night'
    end
{% endmacro %}
