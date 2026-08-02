-- Generated as a fixed calendar spine matching the dataset's designed generation window
-- (scripts/generate_retail_dataset.py START_DATE/END_DATE = 2021-01-01 to 2024-06-30),
-- not derived from MIN/MAX fact dates — those drift outside the intended window
-- (see docs/business_rules/ note on out-of-window fact rows).
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
-- Date range is fixed to the dataset's designed generation window (2021-01-01 to 2024-06-30).
-- fact_payments (44 rows), fact_returns (81 rows), and fact_marketing_touchpoints (853 rows)
-- have dates that fall outside this window in the generated data — those rows will not
-- find a matching dim_date row on date_key. Documented as a known data quality finding,
-- not silently dropped; see docs/business_rules/ for how those rows should be treated.

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

WITH calendar_dates AS (
    -- Fixed spine matching generate_retail_dataset.py's START_DATE/END_DATE constants,
    -- not the MIN/MAX of fact table dates.
    SELECT
        GENERATE_SERIES(
            DATE '2021-01-01',
            DATE '2024-06-30',
            INTERVAL '1 day'
        )::DATE AS full_date
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

