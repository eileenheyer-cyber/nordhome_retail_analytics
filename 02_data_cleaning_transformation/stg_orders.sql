
/*
Orders Table Cleaning

The raw orders table is cleaned and stored as stg.stg_orders.

Cleaning steps:
- Trim text fields
- Parse order_date from 3 text formats (YYYY-MM-DD, DD/MM/YYYY, MM-DD-YYYY) to DATE
- Map country spelling variants to canonical English names (same mapping as stg_customers)
- Standardize order_status, sales_channel, and shipping_method with INITCAP
- Deduplicate on order_id — all duplicates appear exactly twice, keep earliest order_date
- Flag duplicate order_ids, ghost customer references, invalid dates, and invalid statuses

Raw data findings:
- 31,465 rows, 0 missing values across all columns
- All order_ids appear at most twice — no order appears 3+ times
- All 31,465 order_dates matched one of the 3 known formats — no NULL dates expected
- 6 clean order_status values: Completed, Shipped, Processing, Cancelled, Refunded, Returned
- 496 orders reference a customer_id not found in raw_customers (ghost customer references)
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

        -- 3 date formats found in raw data. All 31,465 rows match one of these — no NULL dates expected.
        CASE
            WHEN order_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
                THEN TO_DATE(order_date_raw, 'YYYY-MM-DD')

            WHEN order_date_raw ~ '^\d{2}/\d{2}/\d{4}$'
                THEN TO_DATE(order_date_raw, 'DD/MM/YYYY')

            WHEN order_date_raw ~ '^\d{2}-\d{2}-\d{4}$'
                THEN TO_DATE(order_date_raw, 'MM-DD-YYYY')

            ELSE NULL
        END AS order_date,

        -- 6 clean values found in raw data — INITCAP normalises any unexpected casing variants.
        INITCAP(LOWER(order_status_raw)) AS order_status,

        -- Same 10-market mapping as stg_customers. Raw data contains ISO codes, local names, and English names.
        CASE
            WHEN LOWER(country_raw) IN ('de', 'deutschland', 'germany') THEN 'Germany'
            WHEN LOWER(country_raw) IN ('at', 'austria', 'österreich') THEN 'Austria'
            WHEN LOWER(country_raw) IN ('ch', 'switzerland', 'schweiz') THEN 'Switzerland'
            WHEN LOWER(country_raw) IN ('fr', 'france') THEN 'France'
            WHEN LOWER(country_raw) IN ('nl', 'netherlands', 'the netherlands') THEN 'Netherlands'
            WHEN LOWER(country_raw) IN ('dk', 'denmark') THEN 'Denmark'
            WHEN LOWER(country_raw) IN ('no', 'norway') THEN 'Norway'
            WHEN LOWER(country_raw) IN ('se', 'sweden', 'schweden') THEN 'Sweden'
            WHEN LOWER(country_raw) IN ('be', 'belgium', 'belgien') THEN 'Belgium'
            WHEN LOWER(country_raw) IN ('pl', 'poland', 'polen') THEN 'Poland'
            ELSE INITCAP(NULLIF(TRIM(country_raw), ''))
        END AS country,

        INITCAP(LOWER(sales_channel_raw)) AS sales_channel,
        INITCAP(LOWER(shipping_method_raw)) AS shipping_method

    FROM cleaned_text
),

date_enriched AS (
    SELECT
        *,

        EXTRACT(YEAR FROM order_date)::INT AS order_year,
        EXTRACT(MONTH FROM order_date)::INT AS order_month,
        EXTRACT(QUARTER FROM order_date)::INT AS order_quarter

    FROM converted_values
),

flagged_values AS (
    SELECT
        *,
        COUNT(*) OVER (
            PARTITION BY order_id
        ) AS order_id_record_count,

        -- ASC keeps the earliest order_date as the canonical row — first recorded occurrence is treated as the original.
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY order_date ASC NULLS LAST
        ) AS row_num

    FROM date_enriched
    WHERE order_id IS NOT NULL
),

final AS (
    SELECT
        order_id,
        customer_id,

        order_date,
        order_year,
        order_month,
        order_quarter,

        order_status,
        country,
        sales_channel,
        shipping_method,

        order_id_record_count > 1 AS duplicate_order_id_flag,

        customer_id IS NULL AS missing_customer_id_flag,

        -- Ghost customer: order exists but customer_id is not found in raw_customers.
        -- These are not IDs containing "GHOST" — they are regular-looking IDs missing from the customer master.
        NOT EXISTS (
            SELECT 1 FROM raw.raw_customers rc
            WHERE TRIM(rc.customer_id) = customer_id
        ) AS ghost_customer_flag,

        -- Dataset covers Jan 2021 – Jun 2024. Dates outside this range are flagged as invalid.
        (
            order_date IS NULL
            OR order_date < DATE '2021-01-01'
            OR order_date > DATE '2024-06-30'
        ) AS invalid_order_date_flag,

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