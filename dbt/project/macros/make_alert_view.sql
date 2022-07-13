{% macro make_alert_view(test_schema_name) %}

    {% set alert_view_query %}
        SELECT DISTINCT table_name AS view_name
        FROM information_schema.tables WHERE table_schema = '{{test_schema_name}}'
        AND table_name not like 'etl_alert'
    {% endset %}

    {% set alert_views = run_query(alert_view_query) %}

    {% set a %}
        {%- for v in alert_views.columns[0].values() -%}

            {%- if 'unique' in v %}

            SELECT
                '{{ v }}' as view_name,
                sum(n_records) as n_records
            FROM {{test_schema_name}}.{{ v }}
            GROUP BY view_name
            HAVING sum(n_records) > 0

            {%- elif 'relationships' in v %}

            SELECT
                '{{ v }}' as view_name,
                count(*) as n_records
            FROM {{test_schema_name}}.{{ v }}
            GROUP BY view_name
            HAVING count(*) > 0

            {%- elif 'accepted_values' in v %}

            SELECT
                '{{ v }}' as view_name,
                sum(n_records) as n_records
            FROM {{test_schema_name}}.{{ v }}
            GROUP BY view_name
            HAVING sum(n_records) > 0

            {% elif 'not_null' in v %}

            SELECT
                '{{ v }}' as view_name,
                count(*) as num_records
            FROM {{test_schema_name}}.{{ v }}
            GROUP BY view_name
            HAVING count(*) > 0

            {% endif -%}

        {%- if not loop.last %}
            {{ 'UNION' }}
        {% endif -%}

        {%- endfor -%}
    {%- endset -%}

    {{ print(a) }}

    {% set create_alert_view %}
        CREATE MATERIALIZED VIEW {{ test_schema_name }}.etl_alert AS {{ a }};
    {% endset %}

    {% do run_query(create_alert_view) %}

{% endmacro %}