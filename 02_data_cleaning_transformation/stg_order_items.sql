/*
Order Items Table Cleaning

The raw order items table is cleaned and stored as stg.stg_order_items.

Cleaning steps:
- Trim text fields
- Convert quantity, unit_price, discount, and line_total from text to numeric types
- Fix negative quantities using ABS() — flag with negative_quantity_flag
- Fix extreme quantities (>99) by back-solving the real quantity from
  line_total_original, clamped to 1-5 — flag with extreme_quantity_flag
- Cap discounts between 0 and 1 — flag with discount_range_issue_flag
- Recalculate line_total from cleaned values — flag mismatches with line_total_mismatch_flag
- Flag zero unit prices with zero_unit_price_flag (kept, not set to NULL — unlike list_price in products)
- Flag ghost product references with ghost_product_flag (product_id contains PROD-GHOST-*)

Raw data findings:
- 75,473 rows, 0 missing values, 0 duplicate order_item_ids
- All numeric fields are valid formats — issues are in the values, not the format
- 379 negative quantities, 241 zero unit prices, 299 discounts out of range
- 452 ghost product references — all items_with_no_product are ghost products
- 0 items without a matching order — perfect referential integrity with orders table

Extreme quantity fix (2026-07-18): 228 rows have quantity > 99. The generator
computes line_total from the real quantity (1-5) first, then separately
corrupts the quantity field on some rows — so line_total_original is still
correct, only quantity is broken. We back-solve quantity from
line_total_original instead of guessing a capped value, and trust
line_total_original as the real line_total. Revenue impact: Gross Sales
Revenue drops ~€2.3M (~9%) once this flows through to the mart — see
docs/business_rules/BUSINESS_METADATA.md, which needs its revenue table re-run.
*/

CREATE SCHEMA IF NOT EXISTS stg;

DROP TABLE IF EXISTS stg.stg_order_items;

CREATE TABLE stg.stg_order_items AS
WITH source AS (
    SELECT *
    FROM raw.raw_order_items
),

cleaned_text AS (
    SELECT
        NULLIF(TRIM(order_item_id), '') AS order_item_id,
        NULLIF(TRIM(order_id), '') AS order_id,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(quantity), '') AS quantity_raw,
        NULLIF(TRIM(unit_price), '') AS unit_price_raw,
        NULLIF(TRIM(discount), '') AS discount_raw,
        NULLIF(TRIM(line_total), '') AS line_total_raw
    FROM source
),

converted_values AS (
    SELECT
        order_item_id,
        order_id,
        product_id,
        CASE
            WHEN quantity_raw ~ '^-?[0-9]+$'
                THEN quantity_raw::INTEGER
            ELSE NULL
        END AS quantity_original,
        CASE
            WHEN unit_price_raw ~ '^[0-9]+(\.[0-9]+)?$'
                THEN unit_price_raw::NUMERIC(10, 2)
            ELSE NULL
        END AS unit_price,
        CASE
            WHEN discount_raw ~ '^-?[0-9]+(\.[0-9]+)?$'
                THEN discount_raw::NUMERIC(10, 4)
            ELSE NULL
        END AS discount_original,
        CASE
            WHEN line_total_raw ~ '^-?[0-9]+(\.[0-9]+)?$'
                THEN line_total_raw::NUMERIC(12, 2)
            ELSE NULL
        END AS line_total_original
    FROM cleaned_text
),

cleaned_values AS (
    SELECT
        order_item_id,
        order_id,
        product_id,
        quantity_original,
        CASE
            WHEN quantity_original IS NULL THEN NULL
            ELSE ABS(quantity_original)
        END AS quantity,
        unit_price,
        discount_original,
        CASE
            WHEN discount_original IS NULL THEN NULL
            ELSE LEAST(GREATEST(discount_original, 0), 1)
        END AS discount,
        line_total_original
    FROM converted_values
),

capped_values AS (
    SELECT
        order_item_id,
        order_id,
        product_id,
        quantity_original,
        quantity,
        unit_price,
        discount_original,
        discount,
        line_total_original,
        CASE
            WHEN quantity IS NULL THEN NULL
            WHEN quantity > 99
                -- Extreme quantity: back-solve the real quantity (1-5) from the
                -- original line_total instead of guessing a capped number.
                THEN LEAST(GREATEST(ROUND(line_total_original / NULLIF(unit_price * (1 - discount), 0)), 1), 5)
            ELSE quantity
        END AS quantity_capped
    FROM cleaned_values
),

final AS (
    SELECT
        order_item_id,
        order_id,
        product_id,
        quantity_original,
        quantity,
        quantity_capped,
        unit_price,
        discount_original,
        discount,
        line_total_original,
        CASE
            WHEN quantity > 99
                -- Trust the original total — it was calculated from the real
                -- quantity before the extreme-quantity corruption was applied.
                THEN line_total_original
            WHEN quantity_capped IS NOT NULL
                AND unit_price IS NOT NULL
                AND discount IS NOT NULL
                THEN ROUND(quantity_capped * unit_price * (1 - discount), 2)
            ELSE NULL
        END AS line_total_clean,

        --this whole step does not delete bad rows. It keeps them, but adds columns that tell you what is wrong:issue flags
        quantity_original IS NULL AS invalid_quantity_flag,
        COALESCE(quantity_original < 0, FALSE) AS negative_quantity_flag,
        COALESCE(ABS(quantity_original) > 99, FALSE) AS extreme_quantity_flag,

        unit_price IS NULL AS invalid_unit_price_flag,
        COALESCE(unit_price = 0, FALSE) AS zero_unit_price_flag,

        discount_original IS NULL AS invalid_discount_flag,
        COALESCE(discount_original < 0 OR discount_original > 1, FALSE) AS discount_range_issue_flag,

        COALESCE(product_id LIKE '%GHOST%', FALSE) AS ghost_product_flag, --If product_id contains the word GHOST, mark the row as TRUE.

        CASE                                          -- Does the raw line_total match the revenue formula?
            WHEN line_total_original IS NULL 
                OR quantity_capped IS NULL
                OR unit_price IS NULL
                OR discount IS NULL
                THEN NULL
            WHEN ABS(line_total_original - ROUND(quantity_capped * unit_price * (1 - discount), 2)) > 0.01
                THEN TRUE --for business/revenue analysis, > 0.01 is usually better because it ignores tiny rounding noise.
            ELSE FALSE
        END AS line_total_mismatch_flag,

        CURRENT_TIMESTAMP AS cleaned_at

    FROM capped_values
)

SELECT *
FROM final;
