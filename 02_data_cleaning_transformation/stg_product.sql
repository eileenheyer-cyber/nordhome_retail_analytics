/*
Product Table Cleaning

The raw product table is cleaned and stored as stg.product.

Cleaning steps:
- Trim text fields
- Fill missing category values from subcategory when possible
- Convert unit_cost and list_price from text to NUMERIC
- Convert launch_date from text to DATE
- Convert discontinued_flag from text to BOOLEAN
- Add price_issue_flag for products where list_price < unit_cost

Note:
Only a small number of products had a list_price lower than unit_cost.
These records were not removed or automatically corrected because it is unclear
whether the cost or price value is incorrect. Instead, a price_issue_flag was created
so that these products can be identified and optionally excluded from margin-related analysis.

The product table cleaning is split into CTE steps because prices, dates, categories,
and price_issue_flag depend on earlier cleaned and converted values.
This makes the logic safer and easier to debug.
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

        CASE
            WHEN list_price_raw ~ '^[0-9]+(\.[0-9]+)?$'
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
        END AS discontinued_flag

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

        -- Flag products where the selling price is lower than the cost.
        -- Values are kept unchanged because it is unclear which value is incorrect.
        CASE
            WHEN unit_cost IS NOT NULL
                 AND list_price IS NOT NULL
                 AND list_price < unit_cost
                THEN TRUE
            ELSE FALSE
        END AS price_issue_flag

    FROM converted_values
)

SELECT *
FROM final;
