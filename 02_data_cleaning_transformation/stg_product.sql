/*
Product Table Cleaning

The raw product table is cleaned and stored as stg.stg_products.

Cleaning steps:
- Trim text fields
- Fill missing category values from subcategory when possible (36 products had NULL category)
- Convert unit_cost and list_price from text to NUMERIC
- Convert launch_date from text to DATE (all rows use YYYY-MM-DD in raw data)
- Convert discontinued_flag from text to BOOLEAN (only Y/N values found in raw data)
- Set list_price to NULL where list_price = 0 (treated as missing, not a valid price)
- Add price_issue_flag for products where list_price was 0 or list_price < unit_cost
- Add missing_category_flag for products where category is still NULL after inference

Raw data findings:
- 36 products had NULL category — inferred from subcategory where mapping is clear
- 6 products had list_price = 0.0 — root cause is missing price, not a cost logic error
- No duplicate product_ids, no missing prices/costs, no format issues
*/

CREATE SCHEMA IF NOT EXISTS stg;

DROP TABLE IF EXISTS stg.stg_products;

CREATE TABLE stg.stg_products AS

WITH source AS (
    SELECT *
    FROM raw.raw_products
),

cleaned_text AS (
    SELECT
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(product_name), '') AS product_name,

        NULLIF(TRIM(category), '') AS category_raw,
        NULLIF(TRIM(subcategory), '') AS subcategory,

        NULLIF(TRIM(brand), '') AS brand,

        NULLIF(TRIM(unit_cost), '') AS unit_cost_raw,
        NULLIF(TRIM(list_price), '') AS list_price_raw,

        NULLIF(TRIM(launch_date), '') AS launch_date_raw,
        NULLIF(TRIM(discontinued_flag), '') AS discontinued_flag_raw

    FROM source
),

standardized_category AS (
    SELECT
        product_id,
        product_name,

        CASE
            WHEN category_raw IS NOT NULL THEN INITCAP(category_raw)

            -- If category is missing, infer it from subcategory when the mapping is clear.
            WHEN LOWER(subcategory) IN ('gift sets', 'novelty') THEN 'Gifts'
            WHEN LOWER(subcategory) IN ('skincare', 'haircare', 'bodycare') THEN 'Beauty'
            WHEN LOWER(subcategory) IN ('bedding', 'decor', 'lighting') THEN 'Home'
            WHEN LOWER(subcategory) IN ('utensils', 'cookware', 'kitchenware', 'storage', 'appliance') THEN 'Kitchen'
            WHEN LOWER(subcategory) IN ('wellness', 'stationery', 'travel') THEN 'Lifestyle'

            ELSE NULL
        END AS category,

        INITCAP(subcategory) AS subcategory,

        -- Keep brand spelling as it is after trimming.
        -- INITCAP could damage brand names such as NordHome or CozyLiving.
        brand,

        unit_cost_raw,
        list_price_raw,
        launch_date_raw,
        discontinued_flag_raw

    FROM cleaned_text
),

converted_values AS (
    SELECT
        product_id,
        product_name,
        category,
        subcategory,
        brand,

        CASE
            WHEN unit_cost_raw ~ '^[0-9]+(\.[0-9]+)?$'
                THEN unit_cost_raw::NUMERIC(10,2)
            ELSE NULL
        END AS unit_cost,

        -- Zero prices set to NULL (missing data, not a valid price).
        -- price_issue_flag documents which rows were affected.
        CASE
            WHEN list_price_raw ~ '^[0-9]+(\.[0-9]+)?$'
                 AND list_price_raw::NUMERIC > 0
                THEN list_price_raw::NUMERIC(10,2)
            ELSE NULL
        END AS list_price,

        CASE
            WHEN launch_date_raw ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                THEN TO_DATE(launch_date_raw, 'YYYY-MM-DD')

            WHEN launch_date_raw ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
                THEN TO_DATE(launch_date_raw, 'DD/MM/YYYY')

            WHEN launch_date_raw ~ '^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$'
                THEN TO_DATE(launch_date_raw, 'DD.MM.YYYY')

            ELSE NULL
        END AS launch_date,

        CASE
            WHEN UPPER(discontinued_flag_raw) IN ('Y', 'YES', 'TRUE', '1') THEN TRUE
            WHEN UPPER(discontinued_flag_raw) IN ('N', 'NO', 'FALSE', '0') THEN FALSE
            ELSE NULL
        END AS discontinued_flag,

        -- Computed here while raw values are still accessible.
        -- list_price is set to NULL for zero prices in the step above, so the flag
        -- must be derived from list_price_raw before the zero becomes NULL.
        --
        -- The regex '^[0-9]+(\.[0-9]+)?$' validates that the raw text is a safe number
        -- before casting — prevents a runtime error if the value is empty, NULL, or non-numeric.
        CASE
            WHEN list_price_raw ~ '^[0-9]+(\.[0-9]+)?$'
                 AND list_price_raw::NUMERIC = 0 THEN TRUE
            WHEN list_price_raw ~ '^[0-9]+(\.[0-9]+)?$'
                 AND unit_cost_raw ~ '^[0-9]+(\.[0-9]+)?$'
                 AND list_price_raw::NUMERIC > 0
                 AND list_price_raw::NUMERIC < unit_cost_raw::NUMERIC THEN TRUE
            ELSE FALSE
        END AS price_issue_flag

    FROM standardized_category
),

final AS (
    SELECT
        product_id,
        product_name,
        category,
        subcategory,
        brand,
        unit_cost,
        list_price,
        launch_date,
        discontinued_flag,
        price_issue_flag,

        -- Flag products where category is still NULL after subcategory inference.
        category IS NULL AS missing_category_flag

    FROM converted_values
)

SELECT *
FROM final;
