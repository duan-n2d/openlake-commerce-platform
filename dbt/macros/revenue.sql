{% macro safe_rate(numerator, denominator) -%}
cast({{ numerator }} as double) / nullif({{ denominator }}, 0)
{%- endmacro %}
