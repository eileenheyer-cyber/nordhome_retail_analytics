/*
Raw Data Quality Checks — All Tables

Runs against all 7 raw tables before any cleaning.
Purpose: understand the scope of data issues before writing the staging layer.
All queries are read-only SELECT statements.

Tables covered:
  1. raw_customers
  2. raw_products
  3. raw_orders
  4. raw_order_items
  5. raw_payments
  6. raw_returns
  7. raw_marketing_campaigns
*/


-- =============================================================================
-- 1. RAW_CUSTOMERS
-- =============================================================================

-- 1.1 Row count (expected: ~8,386)
SELECT COUNT(*) AS total_rows
FROM raw.raw_customers;

-- 1.2 Duplicate customer_id (expected: 0)
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM raw.raw_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 1.3 Missing values in key columns
SELECT
    COUNT(*)                                                                        AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL OR TRIM(customer_id) = '')          AS missing_customer_id,
    COUNT(*) FILTER (WHERE first_name IS NULL OR TRIM(first_name) = '')            AS missing_first_name,
    COUNT(*) FILTER (WHERE last_name IS NULL OR TRIM(last_name) = '')              AS missing_last_name,
    COUNT(*) FILTER (WHERE email IS NULL OR TRIM(email) = '')                      AS missing_email,
    COUNT(*) FILTER (WHERE phone IS NULL OR TRIM(phone) = '')                      AS missing_phone,
    COUNT(*) FILTER (WHERE country IS NULL OR TRIM(country) = '')                  AS missing_country,
    COUNT(*) FILTER (WHERE city IS NULL OR TRIM(city) = '')                        AS missing_city,
    COUNT(*) FILTER (WHERE registration_date IS NULL OR TRIM(registration_date) = '') AS missing_registration_date,
    COUNT(*) FILTER (WHERE birth_year IS NULL OR TRIM(birth_year) = '')            AS missing_birth_year,
    COUNT(*) FILTER (WHERE gender IS NULL OR TRIM(gender) = '')                    AS missing_gender,
    COUNT(*) FILTER (WHERE loyalty_member IS NULL OR TRIM(loyalty_member) = '')    AS missing_loyalty_member
FROM raw.raw_customers;

-- 1.4 Invalid email format (expected: ~1,757 invalid)
SELECT
    COUNT(*)                                                                        AS total_rows,
    COUNT(*) FILTER (WHERE email IS NULL OR TRIM(email) = '')                      AS missing_email,
    COUNT(*) FILTER (
        WHERE email IS NOT NULL
          AND TRIM(email) <> ''
          AND email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
    )                                                                               AS invalid_email_format,
    COUNT(*) FILTER (
        WHERE email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
    )                                                                               AS valid_email
FROM raw.raw_customers;

-- 1.5 registration_date format variety (all text — need to identify mixed formats)
SELECT
    CASE
        WHEN registration_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN registration_date ~ '^\d{2}/\d{2}/\d{4}$' THEN 'DD/MM/YYYY'
        WHEN registration_date ~ '^\d{2}-\d{2}-\d{4}$' THEN 'MM-DD-YYYY'
        WHEN registration_date IS NULL OR TRIM(registration_date) = '' THEN 'missing'
        ELSE 'unknown format'
    END AS date_format,
    COUNT(*) AS row_count
FROM raw.raw_customers
GROUP BY 1
ORDER BY row_count DESC;

-- 1.6 loyalty_member value distribution (expected: inconsistent — True/False/1/0/yes/no mix)
SELECT
    loyalty_member,
    COUNT(*) AS row_count
FROM raw.raw_customers
GROUP BY loyalty_member
ORDER BY row_count DESC;

-- 1.7 country value distribution (expected: 10 European markets, some inconsistencies)
SELECT
    country,
    COUNT(*) AS customer_count
FROM raw.raw_customers
GROUP BY country
ORDER BY customer_count DESC;

-- 1.8 birth_year anomalies (check for suffix zeros or non-numeric values)
SELECT
    birth_year,
    COUNT(*) AS row_count
FROM raw.raw_customers
WHERE birth_year !~ '^\d{4}$' OR birth_year IS NULL
GROUP BY birth_year
ORDER BY row_count DESC;


-- =============================================================================
-- 2. RAW_PRODUCTS
-- =============================================================================

-- 2.1 Row count
SELECT COUNT(*) AS total_rows
FROM raw.raw_products;

-- 2.2 Duplicate product_id (expected: 0)
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM raw.raw_products
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 2.3 Missing values in key columns
SELECT
    COUNT(*)                                                                        AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL OR TRIM(product_id) = '')            AS missing_product_id,
    COUNT(*) FILTER (WHERE product_name IS NULL OR TRIM(product_name) = '')        AS missing_product_name,
    COUNT(*) FILTER (WHERE category IS NULL OR TRIM(category) = '')                AS missing_category,
    COUNT(*) FILTER (WHERE subcategory IS NULL OR TRIM(subcategory) = '')          AS missing_subcategory,
    COUNT(*) FILTER (WHERE brand IS NULL OR TRIM(brand) = '')                      AS missing_brand,
    COUNT(*) FILTER (WHERE unit_cost IS NULL OR TRIM(unit_cost) = '')              AS missing_unit_cost,
    COUNT(*) FILTER (WHERE list_price IS NULL OR TRIM(list_price) = '')            AS missing_list_price,
    COUNT(*) FILTER (WHERE launch_date IS NULL OR TRIM(launch_date) = '')          AS missing_launch_date,
    COUNT(*) FILTER (WHERE discontinued_flag IS NULL OR TRIM(discontinued_flag) = '') AS missing_discontinued_flag
FROM raw.raw_products;

-- 2.4 Non-numeric list_price and unit_cost
SELECT
    COUNT(*) FILTER (WHERE list_price !~ '^[0-9]+(\.[0-9]+)?$')  AS non_numeric_list_price,
    COUNT(*) FILTER (WHERE unit_cost !~ '^[0-9]+(\.[0-9]+)?$')   AS non_numeric_unit_cost
FROM raw.raw_products
WHERE list_price IS NOT NULL AND unit_cost IS NOT NULL;

-- 2.5 Category value distribution
SELECT
    category,
    COUNT(*) AS product_count
FROM raw.raw_products
GROUP BY category
ORDER BY product_count DESC;

-- 2.6 discontinued_flag value distribution (check for inconsistent values)
SELECT
    discontinued_flag,
    COUNT(*) AS row_count
FROM raw.raw_products
GROUP BY discontinued_flag
ORDER BY row_count DESC;

-- 2.7 launch_date format variety
SELECT
    CASE
        WHEN launch_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN launch_date ~ '^\d{2}/\d{2}/\d{4}$' THEN 'DD/MM/YYYY'
        WHEN launch_date ~ '^\d{2}-\d{2}-\d{4}$' THEN 'MM-DD-YYYY'
        WHEN launch_date IS NULL OR TRIM(launch_date) = '' THEN 'missing'
        ELSE 'unknown format'
    END AS date_format,
    COUNT(*) AS row_count
FROM raw.raw_products
GROUP BY 1
ORDER BY row_count DESC;


-- =============================================================================
-- 3. RAW_ORDERS
-- =============================================================================

-- 3.1 Row count
SELECT COUNT(*) AS total_rows
FROM raw.raw_orders;

-- 3.2 Duplicate order_id (expected: some duplicates — documented data issue)
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM raw.raw_orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 3.3 Missing values in key columns
SELECT
    COUNT(*)                                                                        AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL OR TRIM(order_id) = '')                AS missing_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL OR TRIM(customer_id) = '')          AS missing_customer_id,
    COUNT(*) FILTER (WHERE order_date IS NULL OR TRIM(order_date) = '')            AS missing_order_date,
    COUNT(*) FILTER (WHERE order_status IS NULL OR TRIM(order_status) = '')        AS missing_order_status,
    COUNT(*) FILTER (WHERE country IS NULL OR TRIM(country) = '')                  AS missing_country,
    COUNT(*) FILTER (WHERE sales_channel IS NULL OR TRIM(sales_channel) = '')      AS missing_sales_channel,
    COUNT(*) FILTER (WHERE shipping_method IS NULL OR TRIM(shipping_method) = '')  AS missing_shipping_method
FROM raw.raw_orders;

-- 3.4 order_date format variety
SELECT
    CASE
        WHEN order_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN order_date ~ '^\d{2}/\d{2}/\d{4}$' THEN 'DD/MM/YYYY'
        WHEN order_date ~ '^\d{2}-\d{2}-\d{4}$' THEN 'MM-DD-YYYY'
        WHEN order_date IS NULL OR TRIM(order_date) = '' THEN 'missing'
        ELSE 'unknown format'
    END AS date_format,
    COUNT(*) AS row_count
FROM raw.raw_orders
GROUP BY 1
ORDER BY row_count DESC;

-- 3.5 order_status value distribution
SELECT
    order_status,
    COUNT(*) AS order_count
FROM raw.raw_orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 3.6 Referential integrity — orders with no matching customer
SELECT COUNT(*) AS orders_with_no_customer
FROM raw.raw_orders o
WHERE NOT EXISTS (
    SELECT 1 FROM raw.raw_customers c WHERE c.customer_id = o.customer_id
);


-- =============================================================================
-- 4. RAW_ORDER_ITEMS
-- =============================================================================

-- 4.1 Row count
SELECT COUNT(*) AS total_rows
FROM raw.raw_order_items;

-- 4.2 Duplicate order_item_id (expected: 0)
SELECT
    order_item_id,
    COUNT(*) AS duplicate_count
FROM raw.raw_order_items
GROUP BY order_item_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 4.3 Missing values in key columns
SELECT
    COUNT(*)                                                                        AS total_rows,
    COUNT(*) FILTER (WHERE order_item_id IS NULL OR TRIM(order_item_id) = '')      AS missing_order_item_id,
    COUNT(*) FILTER (WHERE order_id IS NULL OR TRIM(order_id) = '')                AS missing_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL OR TRIM(product_id) = '')            AS missing_product_id,
    COUNT(*) FILTER (WHERE quantity IS NULL OR TRIM(quantity) = '')                AS missing_quantity,
    COUNT(*) FILTER (WHERE unit_price IS NULL OR TRIM(unit_price) = '')            AS missing_unit_price,
    COUNT(*) FILTER (WHERE discount IS NULL OR TRIM(discount) = '')                AS missing_discount,
    COUNT(*) FILTER (WHERE line_total IS NULL OR TRIM(line_total) = '')            AS missing_line_total
FROM raw.raw_order_items;

-- 4.4 Non-numeric or out-of-range numeric fields
SELECT
    COUNT(*) FILTER (WHERE quantity !~ '^-?[0-9]+(\.[0-9]+)?$')      AS non_numeric_quantity,
    COUNT(*) FILTER (WHERE quantity::NUMERIC < 0)                      AS negative_quantity,
    COUNT(*) FILTER (WHERE quantity::NUMERIC = 0)                      AS zero_quantity,
    COUNT(*) FILTER (WHERE unit_price !~ '^-?[0-9]+(\.[0-9]+)?$')    AS non_numeric_unit_price,
    COUNT(*) FILTER (WHERE unit_price::NUMERIC = 0)                    AS zero_unit_price,
    COUNT(*) FILTER (WHERE discount !~ '^-?[0-9]+(\.[0-9]+)?$')      AS non_numeric_discount,
    COUNT(*) FILTER (
        WHERE discount::NUMERIC < 0 OR discount::NUMERIC > 1
    )                                                                   AS discount_out_of_range
FROM raw.raw_order_items
WHERE quantity ~ '^-?[0-9]+(\.[0-9]+)?$'
  AND unit_price ~ '^-?[0-9]+(\.[0-9]+)?$'
  AND discount ~ '^-?[0-9]+(\.[0-9]+)?$';

-- 4.5 Referential integrity — order_items with no matching order
SELECT COUNT(*) AS items_with_no_order
FROM raw.raw_order_items oi
WHERE NOT EXISTS (
    SELECT 1 FROM raw.raw_orders o WHERE o.order_id = oi.order_id
);

-- 4.6 Referential integrity — order_items with no matching product
SELECT COUNT(*) AS items_with_no_product
FROM raw.raw_order_items oi
WHERE NOT EXISTS (
    SELECT 1 FROM raw.raw_products p WHERE p.product_id = oi.product_id
);


-- =============================================================================
-- 5. RAW_PAYMENTS
-- =============================================================================

-- 5.1 Row count
SELECT COUNT(*) AS total_rows
FROM raw.raw_payments;

-- 5.2 Duplicate payment_id (expected: some duplicates — documented data issue)
SELECT
    payment_id,
    COUNT(*) AS duplicate_count
FROM raw.raw_payments
GROUP BY payment_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 5.3 Missing values in key columns
SELECT
    COUNT(*)                                                                        AS total_rows,
    COUNT(*) FILTER (WHERE payment_id IS NULL OR TRIM(payment_id) = '')            AS missing_payment_id,
    COUNT(*) FILTER (WHERE order_id IS NULL OR TRIM(order_id) = '')                AS missing_order_id,
    COUNT(*) FILTER (WHERE payment_method IS NULL OR TRIM(payment_method) = '')    AS missing_payment_method,
    COUNT(*) FILTER (WHERE payment_status IS NULL OR TRIM(payment_status) = '')    AS missing_payment_status,
    COUNT(*) FILTER (WHERE payment_date IS NULL OR TRIM(payment_date) = '')        AS missing_payment_date,
    COUNT(*) FILTER (WHERE payment_amount IS NULL OR TRIM(payment_amount) = '')    AS missing_payment_amount
FROM raw.raw_payments;

-- 5.4 payment_method value distribution (check for inconsistent labels)
SELECT
    payment_method,
    COUNT(*) AS row_count
FROM raw.raw_payments
GROUP BY payment_method
ORDER BY row_count DESC;

-- 5.5 payment_date format variety
SELECT
    CASE
        WHEN payment_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN payment_date ~ '^\d{2}/\d{2}/\d{4}$' THEN 'DD/MM/YYYY'
        WHEN payment_date ~ '^\d{2}-\d{2}-\d{4}$' THEN 'MM-DD-YYYY'
        WHEN payment_date IS NULL OR TRIM(payment_date) = '' THEN 'missing'
        ELSE 'unknown format'
    END AS date_format,
    COUNT(*) AS row_count
FROM raw.raw_payments
GROUP BY 1
ORDER BY row_count DESC;

-- 5.6 Non-numeric or negative payment_amount
SELECT
    COUNT(*) FILTER (WHERE payment_amount !~ '^-?[0-9]+(\.[0-9]+)?$') AS non_numeric_amount,
    COUNT(*) FILTER (WHERE payment_amount::NUMERIC < 0)                AS negative_amount
FROM raw.raw_payments
WHERE payment_amount ~ '^-?[0-9]+(\.[0-9]+)?$';

-- 5.7 Referential integrity — payments with no matching order
SELECT COUNT(*) AS payments_with_no_order
FROM raw.raw_payments p
WHERE NOT EXISTS (
    SELECT 1 FROM raw.raw_orders o WHERE o.order_id = p.order_id
);


-- =============================================================================
-- 6. RAW_RETURNS
-- =============================================================================

-- 6.1 Row count
SELECT COUNT(*) AS total_rows
FROM raw.raw_returns;

-- 6.2 Duplicate return_id (expected: 0)
SELECT
    return_id,
    COUNT(*) AS duplicate_count
FROM raw.raw_returns
GROUP BY return_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 6.3 Missing values in key columns
SELECT
    COUNT(*)                                                                        AS total_rows,
    COUNT(*) FILTER (WHERE return_id IS NULL OR TRIM(return_id) = '')              AS missing_return_id,
    COUNT(*) FILTER (WHERE order_id IS NULL OR TRIM(order_id) = '')                AS missing_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL OR TRIM(product_id) = '')            AS missing_product_id,
    COUNT(*) FILTER (WHERE return_date IS NULL OR TRIM(return_date) = '')          AS missing_return_date,
    COUNT(*) FILTER (WHERE return_reason IS NULL OR TRIM(return_reason) = '')      AS missing_return_reason,
    COUNT(*) FILTER (WHERE refund_amount IS NULL OR TRIM(refund_amount) = '')      AS missing_refund_amount
FROM raw.raw_returns;

-- 6.4 return_reason value distribution
SELECT
    return_reason,
    COUNT(*) AS row_count
FROM raw.raw_returns
GROUP BY return_reason
ORDER BY row_count DESC;

-- 6.5 return_date format variety
SELECT
    CASE
        WHEN return_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN return_date ~ '^\d{2}/\d{2}/\d{4}$' THEN 'DD/MM/YYYY'
        WHEN return_date ~ '^\d{2}-\d{2}-\d{4}$' THEN 'MM-DD-YYYY'
        WHEN return_date IS NULL OR TRIM(return_date) = '' THEN 'missing'
        ELSE 'unknown format'
    END AS date_format,
    COUNT(*) AS row_count
FROM raw.raw_returns
GROUP BY 1
ORDER BY row_count DESC;

-- 6.6 Negative refund_amount (expected: ~22)
SELECT
    COUNT(*) FILTER (WHERE refund_amount !~ '^-?[0-9]+(\.[0-9]+)?$') AS non_numeric_refund,
    COUNT(*) FILTER (WHERE refund_amount::NUMERIC < 0)                AS negative_refund
FROM raw.raw_returns
WHERE refund_amount ~ '^-?[0-9]+(\.[0-9]+)?$';

-- 6.7 Referential integrity — returns with no matching order
SELECT COUNT(*) AS returns_with_no_order
FROM raw.raw_returns r
WHERE NOT EXISTS (
    SELECT 1 FROM raw.raw_orders o WHERE o.order_id = r.order_id
);

-- 6.8 Referential integrity — returns with no matching product
SELECT COUNT(*) AS returns_with_no_product
FROM raw.raw_returns r
WHERE NOT EXISTS (
    SELECT 1 FROM raw.raw_products p WHERE p.product_id = r.product_id
);


-- =============================================================================
-- 7. RAW_MARKETING_CAMPAIGNS
-- =============================================================================

-- 7.1 Row count
SELECT COUNT(*) AS total_rows
FROM raw.raw_marketing_campaigns;

-- 7.2 Duplicate campaign_id (expected: duplicates exist — campaign_id is a touchpoint ID)
SELECT
    campaign_id,
    COUNT(*) AS duplicate_count
FROM raw.raw_marketing_campaigns
GROUP BY campaign_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 7.3 Missing values in key columns
SELECT
    COUNT(*)                                                                        AS total_rows,
    COUNT(*) FILTER (WHERE campaign_id IS NULL OR TRIM(campaign_id) = '')          AS missing_campaign_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL OR TRIM(customer_id) = '')          AS missing_customer_id,
    COUNT(*) FILTER (WHERE campaign_name IS NULL OR TRIM(campaign_name) = '')      AS missing_campaign_name,
    COUNT(*) FILTER (WHERE channel IS NULL OR TRIM(channel) = '')                  AS missing_channel,
    COUNT(*) FILTER (WHERE campaign_date IS NULL OR TRIM(campaign_date) = '')      AS missing_campaign_date,
    COUNT(*) FILTER (WHERE clicked IS NULL OR TRIM(clicked) = '')                  AS missing_clicked,
    COUNT(*) FILTER (WHERE converted IS NULL OR TRIM(converted) = '')              AS missing_converted
FROM raw.raw_marketing_campaigns;

-- 7.4 channel value distribution (check for inconsistent labels)
SELECT
    channel,
    COUNT(*) AS row_count
FROM raw.raw_marketing_campaigns
GROUP BY channel
ORDER BY row_count DESC;

-- 7.5 campaign_date format variety
SELECT
    CASE
        WHEN campaign_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN campaign_date ~ '^\d{2}/\d{2}/\d{4}$' THEN 'DD/MM/YYYY'
        WHEN campaign_date ~ '^\d{2}-\d{2}-\d{4}$' THEN 'MM-DD-YYYY'
        WHEN campaign_date IS NULL OR TRIM(campaign_date) = '' THEN 'missing'
        ELSE 'unknown format'
    END AS date_format,
    COUNT(*) AS row_count
FROM raw.raw_marketing_campaigns
GROUP BY 1
ORDER BY row_count DESC;

-- 7.6 clicked and converted value distribution (expected: 0 and 1 only, but check for noise)
SELECT
    clicked,
    converted,
    COUNT(*) AS row_count
FROM raw.raw_marketing_campaigns
GROUP BY clicked, converted
ORDER BY row_count DESC;

-- 7.7 Referential integrity — campaign touchpoints with no matching customer
SELECT COUNT(*) AS touchpoints_with_no_customer
FROM raw.raw_marketing_campaigns mc
WHERE NOT EXISTS (
    SELECT 1 FROM raw.raw_customers c WHERE c.customer_id = mc.customer_id
);