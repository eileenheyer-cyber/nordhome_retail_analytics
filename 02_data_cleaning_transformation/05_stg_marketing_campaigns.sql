/*
Marketing Campaigns Table Cleaning

The raw marketing campaigns table is cleaned and stored as stg.stg_marketing_campaigns.

Cleaning steps:
- Trim text fields
- Convert campaign_date from text to DATE
- Convert clicked and converted from text to INTEGER flags
- Standardize campaign name and channel text
- Add issue flags for missing keys, invalid dates, invalid flag values, and ghost customer references
*/

CREATE SCHEMA IF NOT EXISTS stg;

DROP TABLE IF EXISTS stg.stg_marketing_campaigns

CREATE TABLE stg.stg_marketing_campaigns AS
WITH source AS (
    SELECT *
    FROM raw.raw_marketing_campaigns
),

cleaned_text AS (
    SELECT
        NULLIF(TRIM(campaign_id), '') AS campaign_id,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(campaign_name), '') AS campaign_name_raw,
        NULLIF(TRIM(channel), '') AS channel_raw,
        NULLIF(TRIM(campaign_date), '') AS campaign_date_raw,
        NULLIF(TRIM(clicked), '') AS clicked_raw,
        NULLIF(TRIM(converted), '') AS converted_raw
    FROM source
),

converted_values AS (
    SELECT
        campaign_id,
        customer_id,
        INITCAP(campaign_name_raw) AS campaign_name,
        INITCAP(channel_raw) AS channel,
        campaign_date_raw,
        CASE
            WHEN campaign_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
                THEN TO_DATE(campaign_date_raw, 'YYYY-MM-DD')
            WHEN campaign_date_raw ~ '^\d{2}/\d{2}/\d{4}$'
                THEN TO_DATE(campaign_date_raw, 'DD/MM/YYYY')
            WHEN campaign_date_raw ~ '^\d{2}-\d{2}-\d{4}$'
                THEN TO_DATE(campaign_date_raw, 'MM-DD-YYYY')
            ELSE NULL
        END AS campaign_date,
        CASE
            WHEN clicked_raw IN ('0', '1')
                THEN clicked_raw::INTEGER
            ELSE NULL
        END AS clicked,
        CASE
            WHEN converted_raw IN ('0', '1')
                THEN converted_raw::INTEGER
            ELSE NULL
        END AS converted
    FROM cleaned_text
),

flagged_values AS (
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY campaign_id, customer_id, campaign_date) AS campaign_touchpoint_count, --counts how many times the same campaign/customer/date combination appears
        ROW_NUMBER() OVER (
            PARTITION BY campaign_id, customer_id, campaign_date
            ORDER BY campaign_id
        ) AS row_num
    FROM converted_values
    WHERE campaign_id IS NOT NULL
),

final AS (
    SELECT
        campaign_id,
        customer_id,
        campaign_name,
        channel,
        campaign_date,
        clicked,
        converted,
        campaign_touchpoint_count > 1 AS duplicate_touchpoint_flag,
        customer_id IS NULL AS missing_customer_id_flag,
        COALESCE(customer_id LIKE '%GHOST%', FALSE) AS ghost_customer_flag,
        campaign_date IS NULL AS invalid_campaign_date_flag,
        clicked IS NULL AS invalid_clicked_flag,
        converted IS NULL AS invalid_converted_flag,
        COALESCE(converted = 1 AND clicked = 0, FALSE) AS converted_without_click_flag,
        CURRENT_TIMESTAMP AS cleaned_at
    FROM flagged_values
    WHERE row_num = 1
)

SELECT *
FROM final;
