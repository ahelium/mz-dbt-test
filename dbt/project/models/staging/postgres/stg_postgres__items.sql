SELECT
    *
FROM {{ source('postgres','items') }}
