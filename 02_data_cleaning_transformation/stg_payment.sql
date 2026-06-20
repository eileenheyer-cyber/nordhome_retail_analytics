/*
Payments Table Cleaning

The raw payments table is cleaned and stored as stg.stg_payments.

Cleaning steps:
- Trim text fields
- Standardize payment method values
- Standardize payment status values
- Convert payment_date from text to DATE
- Convert payment_amount from text to NUMERIC
- Identify duplicate payment IDs and keep one row per payment_id
- Add issue flags for missing keys, invalid dates, invalid amounts, ghost order references, and payments before order date
*/

/*
Payments Table Cleaning

The raw payments table is cleaned and stored as stg.stg_payments.
*/

CREATE SCHEMA IF NOT EXISTS stg;

DROP TABLE IF EXISTS stg.stg_payments;

CREATE TABLE stg.stg_payments AS
WITH source AS (
    SELECT *
    FROM raw.raw_payments
),

cleaned_text AS (
    SELECT
        NULLIF(TRIM(payment_id), '') AS payment_id,
        NULLIF(TRIM(order_id), '') AS order_id,
        NULLIF(TRIM(payment_method), '') AS payment_method_raw,
        NULLIF(TRIM(payment_status), '') AS payment_status_raw,
        NULLIF(TRIM(payment_date), '') AS payment_date_raw,
        NULLIF(TRIM(payment_amount), '') AS payment_amount_raw
    FROM source
),

converted_values AS (
    SELECT
        payment_id,
        order_id,

        CASE
            WHEN UPPER(payment_method_raw) IN ('CREDIT CARD', 'CREDITCARD', 'CC', 'CARD')
                THEN 'Credit Card'
            WHEN UPPER(payment_method_raw) IN ('DEBIT CARD', 'DEBIT')
                THEN 'Debit Card'
            WHEN UPPER(payment_method_raw) = 'PAYPAL'
                THEN 'PayPal'
            WHEN UPPER(payment_method_raw) IN ('BANK TRANSFER', 'BANKTRANSFER')
                THEN 'Bank Transfer'
            WHEN UPPER(payment_method_raw) IN ('APPLE PAY', 'APPLEPAY')
                THEN 'Apple Pay'
            WHEN UPPER(payment_method_raw) IN ('KLARNA', 'BUY NOW PAY LATER')
                THEN 'Klarna / BNPL'
            ELSE payment_method_raw
        END AS payment_method,

        CASE
            WHEN LOWER(payment_status_raw) = 'paid' THEN 'Paid'
            WHEN LOWER(payment_status_raw) = 'pending' THEN 'Pending'
            WHEN LOWER(payment_status_raw) = 'failed' THEN 'Failed'
            WHEN LOWER(payment_status_raw) = 'refunded' THEN 'Refunded'
            WHEN LOWER(payment_status_raw) = 'partially refunded' THEN 'Partially Refunded'
            ELSE payment_status_raw
        END AS payment_status,

        CASE
            WHEN payment_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
                THEN TO_DATE(payment_date_raw, 'YYYY-MM-DD')
            WHEN payment_date_raw ~ '^\d{2}/\d{2}/\d{4}$'
                THEN TO_DATE(payment_date_raw, 'DD/MM/YYYY')
            WHEN payment_date_raw ~ '^\d{2}-\d{2}-\d{4}$'
                THEN TO_DATE(payment_date_raw, 'MM-DD-YYYY')
            ELSE NULL
        END AS payment_date,

        CASE
            WHEN payment_amount_raw ~ '^-?[0-9]+(\.[0-9]+)?$'
                THEN payment_amount_raw::NUMERIC(12, 2)
            ELSE NULL
        END AS payment_amount
    FROM cleaned_text
),

flagged_values AS (
    SELECT
        p.*,
        o.order_date,
        COUNT(*) OVER (PARTITION BY p.payment_id) AS payment_id_record_count,
        ROW_NUMBER() OVER (
            PARTITION BY p.payment_id
            ORDER BY p.payment_date DESC NULLS LAST
        ) AS row_num
    FROM converted_values AS p
    LEFT JOIN stg.stg_orders AS o
        ON p.order_id = o.order_id
    WHERE p.payment_id IS NOT NULL
),

final AS (
    SELECT
        payment_id,
        order_id,
        payment_method,
        payment_status,
        payment_date,
        payment_amount,

        payment_id_record_count > 1 AS duplicate_payment_id_flag,
        order_id IS NULL AS missing_order_id_flag,
        COALESCE(order_id LIKE '%GHOST%', FALSE) AS ghost_order_flag,

        payment_method IS NULL AS missing_payment_method_flag,

        (
            payment_method IS NOT NULL
            AND payment_method NOT IN (
                'Credit Card',
                'Debit Card',
                'PayPal',
                'Bank Transfer',
                'Apple Pay',
                'Klarna / BNPL'
            )
        ) AS invalid_payment_method_flag,

        (
            payment_status IS NOT NULL
            AND payment_status NOT IN (
                'Paid',
                'Pending',
                'Failed',
                'Refunded',
                'Partially Refunded'
            )
        ) AS invalid_payment_status_flag,

        payment_date IS NULL AS invalid_payment_date_flag,
        payment_amount IS NULL AS invalid_payment_amount_flag,
        COALESCE(payment_amount < 0, FALSE) AS negative_payment_amount_flag,
        COALESCE(payment_date < order_date, FALSE) AS payment_before_order_flag,

        CURRENT_TIMESTAMP AS cleaned_at
    FROM flagged_values
    WHERE row_num = 1
)

SELECT *
FROM final;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE duplicate_payment_id_flag = TRUE) AS duplicate_payment_id_count,
    COUNT(*) FILTER (WHERE missing_order_id_flag = TRUE) AS missing_order_id_count,
    COUNT(*) FILTER (WHERE ghost_order_flag = TRUE) AS ghost_order_count,
    COUNT(*) FILTER (WHERE missing_payment_method_flag = TRUE) AS missing_payment_method_count,
    COUNT(*) FILTER (WHERE invalid_payment_method_flag = TRUE) AS invalid_payment_method_count,
    COUNT(*) FILTER (WHERE invalid_payment_status_flag = TRUE) AS invalid_payment_status_count,
    COUNT(*) FILTER (WHERE invalid_payment_date_flag = TRUE) AS invalid_payment_date_count,
    COUNT(*) FILTER (WHERE invalid_payment_amount_flag = TRUE) AS invalid_payment_amount_count,
    COUNT(*) FILTER (WHERE negative_payment_amount_flag = TRUE) AS negative_payment_amount_count,
    COUNT(*) FILTER (WHERE payment_before_order_flag = TRUE) AS payment_before_order_count
FROM stg.stg_payments;
