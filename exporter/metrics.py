#!/usr/bin/env python3

import prometheus_client as prom
import psycopg2
import time

# Instantiate our gauge. Define a metric to emulate the changes we see from our Materialized view.
ETL_ALERTS = prom.Gauge('etl_alert_rows', 'Pipeline Alerts!', ["view_name"])

if __name__ == '__main__':

    # sleep while alert views are created
    time.sleep(120)

    # Prometheus Server
    prom.start_http_server(80)

    # Materialize has a neat TAIL feature. This code is ripped directly from the docs
    # https://materialize.com/docs/sql/tail/
    dsn = "postgresql://materialize@materialized:6875/materialize?sslmode=disable"
    conn = psycopg2.connect(dsn)

    alerts = {}

    print("TAIL public_test.etl_alert")
    with conn.cursor() as cur:
        cur.execute("DECLARE c CURSOR FOR TAIL public_test.etl_alert")
        while True:
            cur.execute("FETCH ALL c")
            for row in cur:

                mz_timestamp = row[0]
                mz_diff = row[1]
                alert_view = row[2]
                alert_value = row[3]

                if alert_view in alerts:
                    alerts[alert_view] += mz_diff * alert_value
                else:
                    alerts[alert_view] = mz_diff * alert_value

                ETL_ALERTS.labels(view_name=alert_view).set(alerts[alert_view])
