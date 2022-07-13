SELECT
    *
FROM {{ source('postgres','purchases') }}
