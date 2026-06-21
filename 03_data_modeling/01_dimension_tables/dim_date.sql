-- Generated as a calendar table from stg_orders date range — not sourced from a raw table.
CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.dim_date CASCADE;

CREATE TABLE mart.dim_date (
    -- Surrogate-style date key in YYYYMMDD format.
    -- Example: 2025-06-19 becomes 20250619.
    date_key INT PRIMARY KEY,

    -- The actual calendar date.
    full_date DATE UNIQUE,

    -- Calendar attributes used for time-based analysis.
    year INT,
    quarter INT,
    month_number INT,
    month_name TEXT,
    year_month TEXT,

    day_of_month INT,
    day_of_week_number INT,
    day_of_week_name TEXT,

    -- Flag for comparing weekday and weekend behavior.
    is_weekend BOOLEAN
);
-- Insert one row per calendar date into dim_date.
-- The date range is based on the minimum and maximum order date in the staging order table.

INSERT INTO mart.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month_number,
    month_name,
    year_month,
    day_of_month,
    day_of_week_number,
    day_of_week_name,
    is_weekend
)

WITH date_range AS (
    -- Union all date columns across every fact source so dim_date covers the full range
    -- needed for FK joins in fact_order_items, fact_payments, fact_returns, and fact_marketing_touchpoints.
    SELECT MIN(dt) AS min_date, MAX(dt) AS max_date
    FROM (
        SELECT order_date    AS dt FROM stg.stg_orders             WHERE order_date    IS NOT NULL
        UNION ALL
        SELECT payment_date  AS dt FROM stg.stg_payments           WHERE payment_date  IS NOT NULL
        UNION ALL
        SELECT return_date   AS dt FROM stg.stg_returns            WHERE return_date   IS NOT NULL
        UNION ALL
        SELECT campaign_date AS dt FROM stg.stg_marketing_campaigns WHERE campaign_date IS NOT NULL
    ) all_dates
),

calendar_dates AS (
    -- GENERATE_SERIES ensures every calendar date is present even if no order occurred that day.
    SELECT
        GENERATE_SERIES(
            min_date,
            max_date,
            INTERVAL '1 day'
        )::DATE AS full_date
    FROM date_range
)

SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::INT AS date_key,
    full_date,
    EXTRACT(YEAR FROM full_date)::INT    AS year,
    EXTRACT(QUARTER FROM full_date)::INT AS quarter,
    EXTRACT(MONTH FROM full_date)::INT   AS month_number,
    TRIM(TO_CHAR(full_date, 'Mon'))      AS month_name,
    TO_CHAR(full_date, 'YYYY-MM')        AS year_month,
    EXTRACT(DAY FROM full_date)::INT     AS day_of_month,
    -- ISODOW: 1=Monday … 7=Sunday (ISO standard, avoids locale differences)
    EXTRACT(ISODOW FROM full_date)::INT  AS day_of_week_number,
    TRIM(TO_CHAR(full_date, 'Day'))      AS day_of_week_name,
    EXTRACT(ISODOW FROM full_date) IN (6, 7) AS is_weekend

FROM calendar_dates;

