/* Customer Table Cleaning

The `raw.raw_customers` table was cleaned and stored as `staging.customer`.

The purpose of this step is to standardize customer-related data before it is used for analysis or Power BI modelling. Text fields were trimmed, names and location values were standardized, invalid email values were set to `NULL`, and inconsistent country, gender, and loyalty values were mapped into consistent formats.

The `registration_date` column was converted into a proper `DATE` format, and `birth_year` was converted from decimal/text-like values into an integer. Duplicate customer records were handled based on `customer_id`, keeping the record with the latest valid registration date.
*/


/* Customer Table Cleaning */

DROP TABLE IF EXISTS stg.stg_customers;

CREATE TABLE stg.stg_customers AS

WITH standardized AS (
    SELECT
        NULLIF(TRIM(customer_id), '') AS customer_id,

        NULLIF(
            CONCAT_WS(
                ' ',
                INITCAP(NULLIF(TRIM(first_name), '')),
                INITCAP(NULLIF(TRIM(last_name), ''))
            ),
            ''
        ) AS full_name,

        CASE
            WHEN TRIM(email) ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
                THEN LOWER(TRIM(email))
            ELSE NULL
        END AS email,

        CASE
            WHEN phone IS NULL OR TRIM(phone) = ''
                THEN NULL
            ELSE REGEXP_REPLACE(TRIM(phone), '\s+', '', 'g')
        END AS phone,

        CASE 
            WHEN LOWER(TRIM(country)) IN ('de', 'deutschland', 'germany') THEN 'Germany'
            WHEN LOWER(TRIM(country)) IN ('at', 'austria', 'österreich') THEN 'Austria'
            WHEN LOWER(TRIM(country)) IN ('ch', 'switzerland', 'schweiz') THEN 'Switzerland'
            WHEN LOWER(TRIM(country)) IN ('fr', 'france') THEN 'France'
            WHEN LOWER(TRIM(country)) IN ('nl', 'netherlands', 'the netherlands') THEN 'Netherlands'
            WHEN LOWER(TRIM(country)) IN ('dk', 'denmark') THEN 'Denmark'
            WHEN LOWER(TRIM(country)) IN ('no', 'norway') THEN 'Norway'
            WHEN LOWER(TRIM(country)) IN ('se', 'sweden', 'schweden') THEN 'Sweden'
            WHEN LOWER(TRIM(country)) IN ('be', 'belgium', 'belgien') THEN 'Belgium'
            WHEN LOWER(TRIM(country)) IN ('pl', 'poland', 'polen') THEN 'Poland'
            ELSE INITCAP(NULLIF(TRIM(country), ''))
        END AS country,

        INITCAP(NULLIF(TRIM(city), '')) AS city,

        NULLIF(TRIM(gender), '') AS gender,

        NULLIF(TRIM(marketing_channel), '') AS marketing_channel,

        CASE
            WHEN TRIM(registration_date) ~ '^\d{4}-\d{2}-\d{2}$'
                THEN TO_DATE(TRIM(registration_date), 'YYYY-MM-DD')
            WHEN TRIM(registration_date) ~ '^\d{2}/\d{2}/\d{4}$'
                THEN TO_DATE(TRIM(registration_date), 'DD/MM/YYYY')
            WHEN TRIM(registration_date) ~ '^\d{2}\.\d{2}\.\d{4}$'
                THEN TO_DATE(TRIM(registration_date), 'DD.MM.YYYY')
            ELSE NULL
        END AS registration_date,

        CASE 
            WHEN birth_year IS NULL OR TRIM(birth_year) = ''
                THEN NULL
            WHEN TRIM(birth_year) ~ '^\d{4}\.0$'
                THEN CAST(REPLACE(TRIM(birth_year), '.0', '') AS INT)
            WHEN TRIM(birth_year) ~ '^\d{4}$'
                THEN CAST(TRIM(birth_year) AS INT)
            ELSE NULL
        END AS birth_year,

        CASE
            WHEN LOWER(TRIM(loyalty_member::text)) IN ('true', 't', 'yes', 'y', '1') THEN TRUE
            WHEN LOWER(TRIM(loyalty_member::text)) IN ('false', 'f', 'no', 'n', '0') THEN FALSE
            ELSE NULL
        END AS loyalty_member,

        CURRENT_TIMESTAMP AS cleaned_at

    FROM raw.raw_customers
),

deduplicated AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY registration_date DESC NULLS LAST
        ) AS row_num
    FROM standardized
    WHERE customer_id IS NOT NULL  -- check if there is duplicates at all before
)

SELECT
    customer_id,
    full_name,
    email,
    phone,
    country,
    city, 
    gender,
    marketing_channel,
    registration_date,
    birth_year,
    loyalty_member,
    cleaned_at
FROM deduplicated
WHERE row_num = 1;

SELECT count(*)
FROM staging.stg_customers
