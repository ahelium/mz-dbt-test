WITH source AS (

    SELECT * FROM {{ source('segment','json_pageviews') }}

),

converted AS (

    SELECT cast(convert_from(data, 'utf8') AS jsonb) AS data FROM source

),

renamed AS (

    SELECT
        (data->'user_id')::INT AS user_id,
        data->>'email' AS email,
        data->>'url' AS url,
        data->>'channel' AS channel,
        (data->>'received_at')::bigint AS received_at
    FROM converted
)

SELECT *,
    regexp_match(url, '/(products|profiles)/')[1] AS pageview_type,
    (regexp_match(url, '/(?:products|profiles)/(\d+)')[1])::INT AS target_id,
    to_timestamp(received_at) AS received_at_ts
FROM renamed
