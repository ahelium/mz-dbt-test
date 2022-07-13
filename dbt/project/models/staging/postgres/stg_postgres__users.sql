SELECT
    *
FROM {{ source('postgres','users') }}
