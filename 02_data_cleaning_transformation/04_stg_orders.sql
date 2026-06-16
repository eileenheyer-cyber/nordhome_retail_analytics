
/*
Orders Table Cleaning

The raw orders table is cleaned and stored as stg.stg_orders.

Cleaning steps:
- Trim text fields
- Convert order_date from text to DATE
- Standardize order status, country, sales channel, and shipping method text
- Identify duplicate order IDs and keep one row per order_id
- Add issue flags for missing keys, invalid dates, invalid statuses, and ghost customer references
*/

CREATE SCHEMA IF NOT EXISTS stg;

DROP TABLE IF EXISTS stg.stg_orders;

CREATE TABLE stg.stg_orders AS

WITH source AS (
    SELECT *
    FROM raw.raw_orders
),

cleaned_text AS (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(order_date), '') AS order_date_raw,
        NULLIF(TRIM(order_status), '') AS order_status_raw,
        NULLIF(TRIM(country), '') AS country_raw,
        NULLIF(TRIM(sales_channel), '') AS sales_channel_raw,
        NULLIF(TRIM(shipping_method), '') AS shipping_method_raw
    FROM source
),

converted_values AS (
    SELECT
        order_id,
        customer_id,
        order_date_raw,

        CASE
            WHEN order_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
                THEN TO_DATE(order_date_raw, 'YYYY-MM-DD')
            WHEN order_date_raw ~ '^\d{2}/\d{2}/\d{4}$'
                THEN TO_DATE(order_date_raw, 'DD/MM/YYYY')
            WHEN order_date_raw ~ '^\d{2}-\d{2}-\d{4}$'
                THEN TO_DATE(order_date_raw, 'MM-DD-YYYY')
            ELSE NULL
        END AS order_date,

        INITCAP(LOWER(order_status_raw)) AS order_status,
        INITCAP(LOWER(country_raw)) AS country,
        INITCAP(LOWER(sales_channel_raw)) AS sales_channel,
        INITCAP(LOWER(shipping_method_raw)) AS shipping_method

    FROM cleaned_text
),

flagged_values AS (
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY order_id) AS order_id_record_count,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY order_date DESC NULLS LAST
        ) AS row_num
    FROM converted_values
    WHERE order_id IS NOT NULL
),

final AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        order_status,
        country,
        sales_channel,
        shipping_method,

        order_id_record_count > 1 AS duplicate_order_id_flag,
        customer_id IS NULL AS missing_customer_id_flag,
        COALESCE(customer_id LIKE '%GHOST%', FALSE) AS ghost_customer_flag,
        order_date IS NULL AS invalid_order_date_flag,

        COALESCE(
            order_status NOT IN (
                'Completed',
                'Shipped',
                'Processing',
                'Cancelled',
                'Returned',
                'Refunded'
            ),
            TRUE
        ) AS invalid_order_status_flag,

        CURRENT_TIMESTAMP AS cleaned_at

    FROM flagged_values
    WHERE row_num = 1
)

SELECT *
FROM final;
