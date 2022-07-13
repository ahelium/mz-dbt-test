#!/usr/bin/env bash
dbt deps
dbt run
dbt test
dbt run-operation make_alert_view --args '{test_schema_name: public_test}'
