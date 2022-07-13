{{ config(materialized='source') }}

CREATE SOURCE IF NOT EXISTS {{ this }}
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'pageviews'
FORMAT BYTES;
