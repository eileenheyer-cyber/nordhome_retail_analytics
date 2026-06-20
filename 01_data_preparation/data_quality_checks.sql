/*
Raw Data Quality Checks — Customers

Runs against raw.raw_customers before any cleaning.
Purpose: understand the scope of data issues before writing the staging layer.
All queries are read-only SELECT statements.
*/

-- 1. Total row count (expected: ~8,386)
SELECT COUNT(*) AS total_rows
FROM raw.raw_customers;

-- 2. Duplicate customer_id (expected: 0 — each customer should appear once)
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM raw.raw_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 3. Missing values in key columns
SELECT
    COUNT(*)                                                                   AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL)                                AS missing_customer_id,
    COUNT(*) FILTER (WHERE first_name IS NULL OR TRIM(first_name) = '')        AS missing_first_name,
    COUNT(*) FILTER (WHERE last_name IS NULL OR TRIM(last_name) = '')          AS missing_last_name,
    COUNT(*) FILTER (WHERE email IS NULL OR TRIM(email) = '')                  AS missing_email,
    COUNT(*) FILTER (WHERE country IS NULL OR TRIM(country) = '')              AS missing_country,
    COUNT(*) FILTER (WHERE registration_date IS NULL)                          AS missing_registration_date
FROM raw.raw_customers;

-- 4. Duplicate emails (expected: some — different customers sharing email is a data issue)
SELECT
    LOWER(TRIM(email)) AS normalized_email,
    COUNT(*)           AS duplicate_count
FROM raw.raw_customers
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 5. Invalid email format (expected: ~1,757 invalid)
SELECT
    COUNT(*)                                                                    AS total_rows,
    COUNT(*) FILTER (WHERE email IS NULL OR TRIM(email) = '')                  AS missing_email,
    COUNT(*) FILTER (
        WHERE email IS NOT NULL
          AND TRIM(email) <> ''
          AND email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
    )                                                                           AS invalid_email_format,
    COUNT(*) FILTER (
        WHERE email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
    )                                                                           AS valid_email
FROM raw.raw_customers;

-- 6. Country value distribution (expected: 10 European markets)
SELECT
    country,
    COUNT(*) AS customer_count
FROM raw.raw_customers
GROUP BY country
ORDER BY customer_count DESC;

-- 7. Registration date range (note: stored as TEXT, so min/max is lexicographic)
SELECT
    MIN(registration_date) AS earliest_registration_date,
    MAX(registration_date) AS latest_registration_date
FROM raw.raw_customers;