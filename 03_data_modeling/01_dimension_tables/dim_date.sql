-- Create the date dimension table.
-- This table is generated as a calendar table, not copied directly from a raw source table.
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
    -- Define the calendar range needed for the data model.
    -- This ensures the date dimension covers all existing order dates.
    SELECT
        MIN(order_date) AS min_date,
        MAX(order_date) AS max_date
    FROM stg.stg_orders
    WHERE order_date IS NOT NULL
),

calendar_dates AS (
    -- Generate a continuous list of dates between the first and last order date.
    -- This avoids missing dates even if no order happened on a specific day.
    SELECT
        GENERATE_SERIES(
            min_date,
            max_date,
            INTERVAL '1 day'
        )::DATE AS full_date
    FROM date_range
)

SELECT
    -- Convert the date into an integer key for joining with fact tables.
    TO_CHAR(full_date, 'YYYYMMDD')::INT AS date_key,

    full_date,

    -- Extract calendar attributes for year, quarter, and month analysis.
    EXTRACT(YEAR FROM full_date)::INT AS year,
    EXTRACT(QUARTER FROM full_date)::INT AS quarter,
    EXTRACT(MONTH FROM full_date)::INT AS month_number,

    -- Month name is useful for readable reports and dashboards.
    TRIM(TO_CHAR(full_date, 'Mon')) AS month_name,

    -- Year-month is useful for monthly trend analysis.
    TO_CHAR(full_date, 'YYYY-MM') AS year_month,

    -- Extract day-level attributes for daily and weekday analysis.
    EXTRACT(DAY FROM full_date)::INT AS day_of_month,
    EXTRACT(ISODOW FROM full_date)::INT AS day_of_week_number,
    TRIM(TO_CHAR(full_date, 'Day')) AS day_of_week_name,

    -- Mark Saturday and Sunday as weekend days.
    CASE
        WHEN EXTRACT(ISODOW FROM full_date) IN (6, 7)
        THEN TRUE
        ELSE FALSE
    END AS is_weekend

FROM calendar_dates;

