{% macro classify_distance(column_name) %}

case
    when {{ column_name }} < 2 then 'short'
    when {{ column_name }} <= 5 then 'medium'
    else 'long'
end

{% endmacro %}