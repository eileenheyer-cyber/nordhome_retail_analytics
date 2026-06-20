/*
Returns Table Cleaning

The raw returns table is cleaned and stored as stg.stg_returns.

Cleaning steps:
- Trim text fields
- Convert return_date from text to DATE
- Convert refund_amount from text to NUMERIC
- Standardize missing return reasons
- Fix negative refund amounts using ABS()
- Identify duplicate return IDs and keep one row per return_id
- Add issue flags for missing keys, invalid dates, invalid amounts, ghost references, and returns before order date
*/

CREATE SCHEMA IF NOT EXISTS stg;

DROP TABLE IF EXISTS stg.stg_returns;

CREATE TABLE stg.stg_returns AS
WITH source AS (
    SELECT *
    FROM raw.raw_returns
),

cleaned_text AS (
    SELECT
        NULLIF(TRIM(return_id), '') AS return_id,
        NULLIF(TRIM(order_id), '') AS order_id,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(return_date), '') AS return_date_raw,
        NULLIF(TRIM(return_reason), '') AS return_reason_raw,
        NULLIF(TRIM(refund_amount), '') AS refund_amount_raw
    FROM source
),

converted_values AS (
    SELECT
        return_id,
        order_id,
        product_id,
        CASE
            WHEN return_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
                THEN TO_DATE(return_date_raw, 'YYYY-MM-DD')
            WHEN return_date_raw ~ '^\d{2}/\d{2}/\d{4}$'
                THEN TO_DATE(return_date_raw, 'DD/MM/YYYY')
            WHEN return_date_raw ~ '^\d{2}-\d{2}-\d{4}$'
                THEN TO_DATE(return_date_raw, 'MM-DD-YYYY')
            ELSE NULL
        END AS return_date,
        COALESCE(INITCAP(return_reason_raw), 'Not Provided') AS return_reason,
        return_reason_raw,
        CASE
            WHEN refund_amount_raw ~ '^-?[0-9]+(\.[0-9]+)?$'
                THEN refund_amount_raw::NUMERIC(12, 2)
            ELSE NULL
        END AS refund_amount_original
    FROM cleaned_text
),

flagged_values AS (
    SELECT.  -- prepares the returns table for duplicate checks and relationship checks.
        r.*,
        o.order_date,
        o.order_id IS NOT NULL AS order_exists,
        p.product_id IS NOT NULL AS product_exists,
        COUNT(*) OVER (PARTITION BY r.return_id) AS return_id_record_count,
        ROW_NUMBER() OVER (
            PARTITION BY r.return_id
            ORDER BY r.return_date DESC NULLS LAST
        ) AS row_num
    FROM converted_values AS r
    LEFT JOIN stg.stg_orders AS o
        ON r.order_id = o.order_id
    LEFT JOIN stg.stg_products AS p
        ON r.product_id = p.product_id
    WHERE r.return_id IS NOT NULL
),

final AS (
    SELECT
        return_id,
        order_id,
        product_id,
        return_date,
        return_reason,
        refund_amount_original,
        CASE
            WHEN refund_amount_original IS NULL THEN NULL
            ELSE ABS(refund_amount_original)
        END AS refund_amount,
        return_id_record_count > 1 AS duplicate_return_id_flag,
        order_id IS NULL AS missing_order_id_flag,
        product_id IS NULL AS missing_product_id_flag,
        COALESCE(order_id LIKE '%GHOST%', FALSE) AS ghost_order_flag,
        COALESCE(product_id LIKE '%GHOST%', FALSE) AS ghost_product_flag,
        COALESCE(order_id IS NOT NULL AND order_exists = FALSE, FALSE) AS unmatched_order_flag,
        COALESCE(product_id IS NOT NULL AND product_exists = FALSE, FALSE) AS unmatched_product_flag,
        return_date IS NULL AS invalid_return_date_flag,
        return_reason_raw IS NULL AS missing_return_reason_flag,
        refund_amount_original IS NULL AS invalid_refund_amount_flag,
        COALESCE(refund_amount_original < 0, FALSE) AS negative_refund_amount_flag,
        COALESCE(return_date < order_date, FALSE) AS return_before_order_flag,
        CURRENT_TIMESTAMP AS cleaned_at
    FROM flagged_values
    WHERE row_num = 1
)

SELECT *
FROM final;

/*
Validation query

Run the full CREATE TABLE statement above first, then run this query.

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE duplicate_return_id_flag = TRUE) AS duplicate_return_id_count,
    COUNT(*) FILTER (WHERE missing_order_id_flag = TRUE) AS missing_order_id_count,
    COUNT(*) FILTER (WHERE missing_product_id_flag = TRUE) AS missing_product_id_count,
    COUNT(*) FILTER (WHERE ghost_order_flag = TRUE) AS ghost_order_count,
    COUNT(*) FILTER (WHERE ghost_product_flag = TRUE) AS ghost_product_count,
    COUNT(*) FILTER (WHERE unmatched_order_flag = TRUE) AS unmatched_order_count,
    COUNT(*) FILTER (WHERE unmatched_product_flag = TRUE) AS unmatched_product_count,
    COUNT(*) FILTER (WHERE invalid_return_date_flag = TRUE) AS invalid_return_date_count,
    COUNT(*) FILTER (WHERE missing_return_reason_flag = TRUE) AS missing_return_reason_count,
    COUNT(*) FILTER (WHERE invalid_refund_amount_flag = TRUE) AS invalid_refund_amount_count,
    COUNT(*) FILTER (WHERE negative_refund_amount_flag = TRUE) AS negative_refund_amount_count,
    COUNT(*) FILTER (WHERE return_before_order_flag = TRUE) AS return_before_order_count
FROM stg.stg_returns;

*/
