

-- 1. Check all staging tables exist
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'stg'
ORDER BY table_name;


-- 2. Row counts in staging tables
SELECT 'stg_customers' AS table_name, COUNT(*) AS row_count FROM stg.stg_customers
UNION ALL
SELECT 'stg_products', COUNT(*) FROM stg.stg_products
UNION ALL
SELECT 'stg_orders', COUNT(*) FROM stg.stg_orders
UNION ALL
SELECT 'stg_order_items', COUNT(*) FROM stg.stg_order_items
UNION ALL
SELECT 'stg_payments', COUNT(*) FROM stg.stg_payments
UNION ALL
SELECT 'stg_returns', COUNT(*) FROM stg.stg_returns
UNION ALL
SELECT 'stg_marketing_campaigns', COUNT(*) FROM stg.stg_marketing_campaigns;


-- 3. Check primary/business keys are unique
SELECT 'customers' AS table_name, COUNT(*) AS total_rows, COUNT(DISTINCT customer_id) AS distinct_keys
FROM stg.stg_customers
UNION ALL
SELECT 'products', COUNT(*), COUNT(DISTINCT product_id)
FROM stg.stg_products
UNION ALL
SELECT 'orders', COUNT(*), COUNT(DISTINCT order_id)
FROM stg.stg_orders
UNION ALL
SELECT 'order_items', COUNT(*), COUNT(DISTINCT order_item_id)
FROM stg.stg_order_items
UNION ALL
SELECT 'payments', COUNT(*), COUNT(DISTINCT payment_id)
FROM stg.stg_payments
UNION ALL
SELECT 'returns', COUNT(*), COUNT(DISTINCT return_id)
FROM stg.stg_returns;

-- 4. Check date columns converted correctly
SELECT 'customers registration_date' AS check_name, COUNT(*) AS null_dates --883 null_dates
FROM stg.stg_customers
WHERE registration_date IS NULL
UNION ALL
SELECT 'products launch_date', COUNT(*)
FROM stg.stg_products
WHERE launch_date IS NULL
UNION ALL
SELECT 'orders order_date', COUNT(*)
FROM stg.stg_orders
WHERE order_date IS NULL
UNION ALL
SELECT 'payments payment_date', COUNT(*)
FROM stg.stg_payments
WHERE payment_date IS NULL
UNION ALL
SELECT 'returns return_date', COUNT(*)
FROM stg.stg_returns
WHERE return_date IS NULL
UNION ALL
SELECT 'campaigns campaign_date', COUNT(*)
FROM stg.stg_marketing_campaigns
WHERE campaign_date IS NULL;


-- 5. Check relationship integrity
SELECT 'orders without customer' AS issue, COUNT(*) AS issue_count
FROM stg.stg_orders o
LEFT JOIN stg.stg_customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT 'order_items without order', COUNT(*)
FROM stg.stg_order_items oi
LEFT JOIN stg.stg_orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'order_items without product', COUNT(*)
FROM stg.stg_order_items oi
LEFT JOIN stg.stg_products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT 'payments without order', COUNT(*)
FROM stg.stg_payments p
LEFT JOIN stg.stg_orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'returns without order', COUNT(*)
FROM stg.stg_returns r
LEFT JOIN stg.stg_orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'returns without product', COUNT(*)
FROM stg.stg_returns r
LEFT JOIN stg.stg_products p ON r.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 6. Check numeric business rules
SELECT 'order_items negative quantity' AS issue, COUNT(*) AS issue_count
FROM stg.stg_order_items
WHERE quantity < 0
UNION ALL
SELECT 'order_items discount outside 0-1', COUNT(*)
FROM stg.stg_order_items
WHERE discount < 0 OR discount > 1
UNION ALL
SELECT 'payments negative amount', COUNT(*)
FROM stg.stg_payments
WHERE payment_amount < 0
UNION ALL
SELECT 'returns negative refund amount', COUNT(*)
FROM stg.stg_returns
WHERE refund_amount < 0;


-- 7. Count all flags across staging tables
SELECT 'order_items flags' AS table_name, COUNT(*) AS flagged_rows
FROM stg.stg_order_items
WHERE negative_quantity_flag
   OR extreme_quantity_flag
   OR zero_unit_price_flag
   OR discount_range_issue_flag
   OR ghost_product_flag
   OR line_total_mismatch_flag

UNION ALL

SELECT 'orders flags', COUNT(*)
FROM stg.stg_orders
WHERE duplicate_order_id_flag
   OR ghost_customer_flag
   OR invalid_order_date_flag
   OR invalid_order_status_flag

UNION ALL

SELECT 'payments flags', COUNT(*)
FROM stg.stg_payments
WHERE duplicate_payment_id_flag
   OR ghost_order_flag
   OR missing_payment_method_flag
   OR payment_before_order_flag

UNION ALL

SELECT 'returns flags', COUNT(*)
FROM stg.stg_returns
WHERE ghost_order_flag
   OR ghost_product_flag
   OR unmatched_order_flag
   OR unmatched_product_flag
   OR missing_return_reason_flag
   OR negative_refund_amount_flag
   OR return_before_order_flag

UNION ALL

SELECT 'marketing flags', COUNT(*)
FROM stg.stg_marketing_campaigns
WHERE duplicate_touchpoint_flag
   OR ghost_customer_flag
   OR invalid_campaign_date_flag
   OR invalid_clicked_flag
   OR invalid_converted_flag
   OR converted_without_click_flag;


-- row count
SELECT COUNT(*) FROM stg.stg_customers;

-- duplicate customer_id
SELECT customer_id, COUNT(*)
FROM stg.stg_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- missing important keys
SELECT COUNT(*)
FROM stg.stg_orders
WHERE customer_id IS NULL;

-- invalid numeric logic
SELECT *
FROM stg.stg_order_items
WHERE quantity <= 0 OR unit_price < 0;



SELECT
    COUNT(*) AS ghost_order_item_rows,
    COUNT(DISTINCT oi.product_id) AS ghost_product_ids,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stg.stg_order_items),
        2
    ) AS ghost_row_percentage
FROM stg.stg_order_items oi
LEFT JOIN stg.stg_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT
    COUNT(*) AS ghost_rows,
    ROUND(SUM(quantity_capped * unit_price), 2) AS affected_gross_revenue,
    ROUND(
        SUM(quantity_capped * unit_price) * 100.0
        / (SELECT SUM(quantity_capped * unit_price)
           FROM stg.stg_order_items),
        2
    ) AS affected_revenue_percentage
FROM stg.stg_order_items oi
LEFT JOIN stg.stg_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


SELECT
    COUNT(*) AS orders_without_customer,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stg.stg_orders),
        2
    ) AS order_percentage
FROM stg.stg_orders o
LEFT JOIN stg.stg_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
    COUNT(DISTINCT o.order_id) AS orders_without_customer,
    ROUND(SUM(oi.quantity_capped * oi.unit_price), 2) AS affected_gross_revenue,
    ROUND(
        SUM(oi.quantity_capped * oi.unit_price) * 100.0
        / (SELECT SUM(quantity_capped * unit_price)
           FROM stg.stg_order_items),
        2
    ) AS affected_revenue_percentage
FROM stg.stg_orders o
LEFT JOIN stg.stg_customers c
    ON o.customer_id = c.customer_id
LEFT JOIN stg.stg_order_items oi
    ON o.order_id = oi.order_id
WHERE c.customer_id IS NULL;

SELECT
    COUNT(*) AS payments_without_order,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stg.stg_payments),
        2
    ) AS payment_percentage
FROM stg.stg_payments p
LEFT JOIN stg.stg_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT
    COUNT(*) AS payments_without_order,
    ROUND(SUM(payment_amount), 2) AS affected_payment_amount,
    ROUND(
        SUM(payment_amount) * 100.0
        / (SELECT SUM(payment_amount)
           FROM stg.stg_payments),
        2
    ) AS affected_payment_percentage
FROM stg.stg_payments p
LEFT JOIN stg.stg_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT
    COUNT(*) AS returns_without_order,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stg.stg_returns),
        2
    ) AS return_percentage
FROM stg.stg_returns r
LEFT JOIN stg.stg_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT
    COUNT(*) AS returns_without_product,
    COUNT(DISTINCT r.product_id) AS missing_return_product_ids,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stg.stg_returns),
        2
    ) AS return_row_percentage
FROM stg.stg_returns r
LEFT JOIN stg.stg_products p
    ON r.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT
    r.product_id,
    COUNT(*) AS return_count
FROM stg.stg_returns r
LEFT JOIN stg.stg_products p
    ON r.product_id = p.product_id
WHERE p.product_id IS NULL
GROUP BY r.product_id
ORDER BY return_count DESC
LIMIT 50;

SELECT
    CASE
        WHEN r.product_id LIKE 'PROD-GHOST-%' THEN 'ghost product id'
        WHEN r.product_id IS NULL THEN 'missing product_id'
        ELSE 'other missing product reference'
    END AS missing_product_type,
    COUNT(*) AS row_count
FROM stg.stg_returns r
LEFT JOIN stg.stg_products p
    ON r.product_id = p.product_id
WHERE p.product_id IS NULL
GROUP BY missing_product_type
ORDER BY row_count DESC;



WITH missing_return_products AS (
    SELECT r.*
    FROM stg.stg_returns r
    LEFT JOIN stg.stg_products p
        ON r.product_id = p.product_id
    WHERE p.product_id IS NULL
)

SELECT
    COUNT(*) AS returns_without_product,

    COUNT(*) FILTER (
        WHERE EXISTS (
            SELECT 1
            FROM stg.stg_order_items oi
            WHERE oi.order_id = missing_return_products.order_id
              AND oi.product_id = missing_return_products.product_id
        )
    ) AS matched_to_order_item,

    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM stg.stg_order_items oi
            WHERE oi.order_id = missing_return_products.order_id
              AND oi.product_id = missing_return_products.product_id
        )
    ) AS not_matched_to_order_item
FROM missing_return_products;

WITH ghost_returns AS (
    SELECT
        r.*,
        'PROD-' || REPLACE(r.product_id, 'PROD-GHOST-', '') AS candidate_plain,
        'PROD-' || LPAD(REPLACE(r.product_id, 'PROD-GHOST-', ''), 6, '0') AS candidate_padded
    FROM stg.stg_returns r
    WHERE r.product_id LIKE 'PROD-GHOST-%'
)

SELECT
    COUNT(*) AS ghost_return_rows,

    COUNT(*) FILTER (
        WHERE p_plain.product_id IS NOT NULL
    ) AS matched_plain_product_id,

    COUNT(*) FILTER (
        WHERE p_padded.product_id IS NOT NULL
    ) AS matched_padded_product_id

FROM ghost_returns gr
LEFT JOIN stg.stg_products p_plain
    ON gr.candidate_plain = p_plain.product_id
LEFT JOIN stg.stg_products p_padded
    ON gr.candidate_padded = p_padded.product_id;

SELECT
    COUNT(*) AS ghost_rows,
    ROUND(SUM(quantity_capped * unit_price), 2) AS affected_gross_revenue,
    ROUND(
        SUM(quantity_capped * unit_price) * 100.0
        / (
            SELECT SUM(quantity_capped * unit_price)
            FROM stg.stg_order_items
        ),
        2
    ) AS affected_revenue_percentage
FROM stg.stg_order_items oi
LEFT JOIN stg.stg_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


WITH ghost_ids AS (
    SELECT DISTINCT product_id
    FROM stg.stg_order_items
    WHERE product_id LIKE 'PROD-GHOST-%'

    UNION

    SELECT DISTINCT product_id
    FROM stg.stg_returns
    WHERE product_id LIKE 'PROD-GHOST-%'
)

SELECT
    COUNT(DISTINCT g.product_id) AS ghost_product_ids,
    COUNT(DISTINCT rp.product_id) AS found_in_raw_products,
    COUNT(DISTINCT sp.product_id) AS found_in_stg_products
FROM ghost_ids g
LEFT JOIN raw.raw_products rp
    ON TRIM(g.product_id) = TRIM(rp.product_id)
LEFT JOIN stg.stg_products sp
    ON g.product_id = sp.product_id;

SELECT
*
FROM stg.stg_orders
where order_id LIKE 'PROD-GHOST-%'


SELECT
    order_quality_status,
    COUNT(*) AS status_count
FROM mart.dim_order
GROUP BY order_quality_status
ORDER BY status_count DESC;

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE invalid_order_date_flag = TRUE) AS invalid_order_date_count,
    ROUND(
        COUNT(*) FILTER (WHERE invalid_order_date_flag = TRUE) * 100.0 / COUNT(*),
        2
    ) AS invalid_order_date_percentage
FROM stg.stg_orders;



SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'stg'
  AND table_name = 'stg_orders'
ORDER BY ordinal_position;

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_date IS NULL
    ) AS missing_or_failed_date_count,

    COUNT(*) FILTER (
        WHERE order_date < DATE '2021-01-01'
    ) AS before_expected_period_count,

    COUNT(*) FILTER (
        WHERE order_date > DATE '2024-06-30'
    ) AS after_expected_period_count

FROM stg.stg_orders;


SELECT *
FROM stg.stg_marketing_campaigns
LIMIT 20;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT campaign_id) AS distinct_campaign_ids,
    COUNT(DISTINCT campaign_name) AS distinct_campaign_names,
    COUNT(DISTINCT CONCAT_WS('|', campaign_name, channel)) AS distinct_campaign_channel_combinations
FROM stg.stg_marketing_campaigns;

SELECT
    campaign_name,
    channel,
    COUNT(*) AS rows,
    COUNT(DISTINCT campaign_id) AS campaign_ids,
    COUNT(DISTINCT customer_id) AS customers,
    SUM(clicked) AS total_clicks,
    SUM(converted) AS total_conversions
FROM stg.stg_marketing_campaigns
GROUP BY campaign_name, channel
ORDER BY rows DESC;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT campaign_id) AS distinct_campaign_ids,
    COUNT(DISTINCT campaign_name) AS distinct_campaign_names,
    COUNT(DISTINCT CONCAT_WS('|', campaign_name, channel)) AS distinct_campaign_channel_combinations
FROM stg.stg_marketing_campaigns;

SELECT
COUNT(*) OVER (
    PARTITION BY customer_id, campaign_name, channel, campaign_date
) AS campaign_touchpoint_count
from stg.stg_marketing_campaigns;

SELECT
    COUNT(*) AS duplicate_groups
FROM stg.stg_marketing_campaigns
WHERE duplicate_touchpoint_flag = TRUE;


SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE campaign_name IS NULL
    ) AS missing_campaign_name,

    COUNT(*) FILTER (
        WHERE channel IS NULL
    ) AS missing_channel,

    COUNT(*) FILTER (
        WHERE campaign_name IS NULL OR channel IS NULL
    ) AS rows_needing_unknown_campaign
FROM stg.stg_marketing_campaigns;SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE campaign_name IS NULL
    ) AS missing_campaign_name,

    COUNT(*) FILTER (
        WHERE channel IS NULL
    ) AS missing_channel,

    COUNT(*) FILTER (
        WHERE campaign_name IS NULL OR channel IS NULL
    ) AS rows_needing_unknown_campaign
FROM stg.stg_marketing_campaigns;

SELECT *
FROM mart.dim_marketing_campaigns
ORDER BY campaign_key
LIMIT 50;

SELECT COUNT(*) AS total_campaign_dimension_rows
FROM mart.dim_marketing_campaigns;

SELECT *
FROM mart.dim_marketing_campaigns
WHERE campaign_key = -1;

SELECT
    campaign_name,
    channel,
    COUNT(*) AS row_count
FROM mart.dim_marketing_campaigns
GROUP BY
    campaign_name,
    channel
HAVING COUNT(*) > 1;

SELECT
    COUNT(*) FILTER (WHERE campaign_key IS NULL) AS null_campaign_keys,
    COUNT(*) FILTER (WHERE campaign_name IS NULL) AS null_campaign_names,
    COUNT(*) FILTER (WHERE channel IS NULL) AS null_channels
FROM mart.dim_marketing_campaigns;

SELECT
    (SELECT COUNT(*) FROM mart.dim_marketing_campaigns) AS dim_rows,
    (SELECT COUNT(DISTINCT CONCAT_WS('|', campaign_name, channel))
     FROM stg.stg_marketing_campaigns) AS staging_campaign_channel_combinations;



select *
from stg.stg_payments
limit 20