/*
1. Customer Dimension Table

This step creates the customer dimension table for the star schema.
Each cleaned customer from stg.stg_customers is stored as one row in mart.dim_customer.

The generated customer_key is used as the surrogate key for joins with fact tables.
The original customer_id is kept as the business key from the source system.
*/

DROP TABLE IF EXISTS mart.dim_customer;

-- create the table structurre
CREATE TABLE mart.dim_customer (
    customer_key INT PRIMARY KEY,
    customer_id TEXT UNIQUE,

    full_name TEXT,
    email TEXT,
    phone TEXT,

    country TEXT,
    gender TEXT,

    birth_year INT,
    age_group TEXT,

    registration_date DATE,
    registration_year INT,

    loyalty_member BOOLEAN,

    missing_email_flag BOOLEAN,
    missing_phone_flag BOOLEAN,
    missing_registration_date_flag BOOLEAN,

    is_unknown_customer BOOLEAN
);

-- Insert the unknown customer row ,creates one artificial fallback customer.
INSERT INTO mart.dim_customer (
    customer_key,
    customer_id,
    full_name,
    email,
    phone,
    country,
    gender,
    birth_year,
    age_group,
    registration_date,
    registration_year,
    loyalty_member,
    missing_email_flag,
    missing_phone_flag,
    missing_registration_date_flag,
    is_unknown_customer
)
VALUES (
    -1,    --special surrogate key for unknown customer, means “we could not assign this fact row to a known customer”.
    'UNKNOWN',    --artificial business key
    'Unknown Customer',
    NULL, --no email known
    NULL, --no phone known
    'Unknown', --country unknown
    'Unknown',  --gender unknown
    NULL,       -- birth year unknown
    'Unknown',   --age group unknown
    NULL,        --registration date unknown
    NULL,        --registration year unknown
    NULL,      --loyalty status unknown
    TRUE,      -- email is missing
    TRUE,  --phone is missing
    TRUE,  --  registration data is missing
    TRUE --this is not a real customer
);

-- Insert real customers,loads all real customers from your cleaned customer table.

INSERT INTO mart.dim_customer (
    customer_key,
    customer_id,
    full_name,
    email,
    phone,
    country,
    gender,
    birth_year,
    age_group,
    registration_date,
    registration_year,
    loyalty_member,
    missing_email_flag,
    missing_phone_flag,
    missing_registration_date_flag,
    is_unknown_customer
)
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_key,

    customer_id,
    full_name,
    email,
    phone,

    COALESCE(country, 'Unknown') AS country,
    COALESCE(gender, 'Unknown') AS gender,

    birth_year,

    CASE
        WHEN birth_year IS NULL THEN 'Unknown'
        WHEN birth_year >= 2010 THEN 'Under 18'
        WHEN birth_year BETWEEN 1997 AND 2009 THEN '18-29'
        WHEN birth_year BETWEEN 1987 AND 1996 THEN '30-39'
        WHEN birth_year BETWEEN 1977 AND 1986 THEN '40-49'
        WHEN birth_year BETWEEN 1967 AND 1976 THEN '50-59'
        WHEN birth_year < 1967 THEN '60+'
        ELSE 'Unknown'
    END AS age_group,

    registration_date,

    EXTRACT(YEAR FROM registration_date)::INT AS registration_year,

    loyalty_member,

    CASE WHEN email IS NULL THEN TRUE ELSE FALSE END AS missing_email_flag,
    CASE WHEN phone IS NULL THEN TRUE ELSE FALSE END AS missing_phone_flag,
    CASE WHEN registration_date IS NULL THEN TRUE ELSE FALSE END AS missing_registration_date_flag,

    FALSE AS is_unknown_customer

FROM stg.stg_customers
WHERE customer_id IS NOT NULL;  --customers without customer_id should not become normal dimension rows.

