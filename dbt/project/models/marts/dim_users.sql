{{ config(materialized='materializedview') }}

WITH pageviews AS (
    SELECT
        user_id,
        email,
        COUNT(*) AS pageviews,
        max(to_timestamp(received_at)) as last_pageview_ts,
        min(to_timestamp(received_at)) as first_pageview_ts
    FROM {{ ref('stg_segment__pageviews') }}
    WHERE pageview_type = 'products'
    GROUP BY user_id, email
),

purchases AS (
    SELECT
        user_id,
        SUM(purchase_price) AS revenue,
        COUNT(id) AS orders,
        SUM(quantity) AS items_sold,
        MAX(event_ts) AS last_purchase_ts,
        MIN(event_ts) AS first_purchase_ts
    FROM {{ ref('stg_postgres__purchases') }}
    GROUP BY user_id
)

SELECT
    users.*,
    purchases.revenue,
    purchases.orders,
    purchases.items_sold,
    purchases.last_purchase_ts,
    purchases.first_purchase_ts,
    pageviews.pageviews,
    pageviews.last_pageview_ts,
    pageviews.first_pageview_ts
FROM {{ ref('stg_postgres__users') }} AS users
JOIN purchases ON users.id = purchases.user_id
JOIN pageviews on users.id = pageviews.user_id
