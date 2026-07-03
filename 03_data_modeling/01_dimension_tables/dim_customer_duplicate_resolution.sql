/*
Duplicate Customer Identity Resolution

Some real customers registered more than once under different customer_id
values (same email, same name, often same phone/registration_date). This
script flags those duplicates and links each one to a canonical customer_key,
without merging or deleting any existing rows.

Additive only — safe to re-run. Does not touch fact_order_items or its
FK to dim_customer.customer_key.

Match key: email (case-sensitive exact match, is_unknown_customer excluded).
Canonical row: earliest registration_date (NULLS LAST), lowest customer_key
as tiebreaker — consistent with this project's existing dedup convention.
*/

ALTER TABLE mart.dim_customer
    ADD COLUMN IF NOT EXISTS duplicate_customer_flag BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS canonical_customer_key  INT;

-- Every customer defaults to being their own canonical record.
UPDATE mart.dim_customer
SET canonical_customer_key = customer_key
WHERE is_unknown_customer = false
  AND canonical_customer_key IS NULL;

-- Identify same-email groups and resolve each to a canonical customer_key.
WITH email_groups AS (
    SELECT
        customer_key,
        email,
        ROW_NUMBER() OVER (
            PARTITION BY email
            ORDER BY registration_date ASC NULLS LAST, customer_key ASC
        ) AS rn,
        FIRST_VALUE(customer_key) OVER (
            PARTITION BY email
            ORDER BY registration_date ASC NULLS LAST, customer_key ASC
        ) AS canonical_key,
        COUNT(*) OVER (PARTITION BY email) AS email_group_size
    FROM mart.dim_customer
    WHERE is_unknown_customer = false
      AND email IS NOT NULL
)
UPDATE mart.dim_customer dc
SET
    duplicate_customer_flag = (eg.rn > 1),
    canonical_customer_key  = eg.canonical_key
FROM email_groups eg
WHERE dc.customer_key = eg.customer_key
  AND eg.email_group_size > 1;