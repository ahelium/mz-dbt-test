{{ config(materialized='materializedview') }}

WITH pageviews AS (
    SELECT
        target_id AS item_id,
        COUNT(*) AS pageviews
    FROM {{ ref('stg_segment__pageviews') }}
    WHERE pageview_type = 'products'
    GROUP BY target_id
),

purchases AS (
    SELECT
        item_id,
        SUM(purchase_price) AS revenue,
        COUNT(id) AS orders,
        SUM(quantity) AS items_sold
    FROM {{ ref('stg_postgres__purchases') }}
    GROUP BY item_id
)

SELECT
    items.*,
    purchases.revenue,
    purchases.orders,
    purchases.items_sold,
    pageviews.pageviews
FROM {{ ref('stg_postgres__items') }} AS items
lEFT JOIN purchases ON items.id = purchases.item_id
LEFT JOIN pageviews ON items.id = pageviews.item_id
