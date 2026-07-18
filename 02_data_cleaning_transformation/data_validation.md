# Data Validation

This document records validation checks run after creating the staging tables. The goal is to confirm that the cleaned `stg` tables were created correctly and are ready for data modeling.

## 1. Staging Table Row Counts

**Purpose:** Confirm that all expected staging tables were created and contain data.

```sql
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
```

**Result:**

| Table name                | Row count |
| ------------------------- | --------- |
| `stg_products`            | 1090      |
| `stg_returns`             | 6097      |
| `stg_customers`           | 8364      |
| `stg_marketing_campaigns` | 12000     |
| `stg_payments`            | 31465     |
| `stg_orders`              | 31000     |
| `stg_order_items`         | 75473     |

**Interpretation:** All expected staging tables exist and contain records. Differences from raw row counts are expected — stg_orders (31,000 vs raw 31,465) and stg_payments (31,465 vs raw 31,936) had duplicate rows removed during staging.


## 2. Business Key Uniqueness

**Purpose:** Confirm that the main business key in each staging table is unique after cleaning and deduplication.

```sql
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
FROM stg.stg_returns
UNION ALL
SELECT 'marketing_campaigns', COUNT(*), COUNT(DISTINCT marketing_touchpoint_id)
FROM stg.stg_marketing_campaigns;
```

**Result:**

| Table name               | Total rows | Distinct keys |
| ------------------------ | ---------- | ------------- |
| `products`               | 1090       | 1090          |
| `returns`                | 6097       | 6097          |
| `customers`              | 8364       | 8364          |
| `orders`                 | 31000      | 31000         |
| `payments`               | 31465      | 31465         |
| `order_items`            | 75473      | 75473         |
| `marketing_campaigns`    | 12000      | 12000         |

**Interpretation:** For each staging table, the total row count matches the distinct key count. This confirms that duplicate business keys were successfully removed or resolved during staging.

> **Note — marketing_campaigns:** The 12,000 / 12,000 result for `marketing_touchpoint_id` is expected but does not mean the campaign business key is clean. `marketing_touchpoint_id` is a row-level interaction identifier, not a reusable campaign key — every row is unique by design. The real campaign grain is `campaign_name + channel`, which produces 98 distinct combinations. This will be handled in `dim_marketing_campaigns`. See Section 7 for full analysis.

## 3. Relationship Integrity

**Purpose:** Check whether records in child tables can join to their expected parent tables.

This validation checks:
- orders to customers
- order items to orders
- order items to products
- payments to orders
- returns to orders
- returns to products

```sql
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
```

**Result:**

| issue                       | issue_count |
| --------------------------- | ----------- |
| returns without product     | 1835        |
| returns without order       | 60          |
| orders without customer     | 248         |
| payments without order      | 220         |
| order_items without product | 452         |
| order_items without order   | 0           |

**Interpretation:** Most staging relationships are valid, but some records still cannot join to their parent tables. The largest relationship issue is returns without matching products, followed by order items without products, orders without customers, payments without orders, and returns without orders. These issues were preserved with flags in the staging tables for review before modeling.


## 4. Numeric Business Rules

**Purpose:** Confirm that cleaned numeric fields no longer violate core business rules.

This validation checks:
- order item quantity is not negative
- order item discount is between 0 and 1
- payment amount is not negative
- return refund amount is not negative

```sql
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
```

**Result:**

| issue                            | issue_count |
| -------------------------------- | ----------- |
| returns negative refund amount   | 0           |
| payments negative amount         | 0           |
| order_items negative quantity    | 0           |
| order_items discount outside 0-1 | 0           |

**Interpretation:** The cleaned numeric fields pass the business-rule checks. Negative quantities, invalid discount ranges, negative payment amounts, and negative refund amounts no longer remain in the cleaned staging values.

## 5. Remaining Flagged Rows

**Purpose:** Summarize how many staging rows still contain one or more data quality flags after cleaning.

These flagged rows were intentionally kept in staging for transparency and review. They do not always mean the row should be deleted; many represent business-rule or referential-integrity issues that should be handled during modeling or analysis.

```sql
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
```

**Result:**

| table_name        | flagged_rows |
| ----------------- | ------------ |
| returns flags     | 2379         |
| marketing flags   | 0            |
| payments flags    | 2758         |
| orders flags      | 465          |
| order_items flags | 3766         |

**Interpretation:** Marketing campaign records have no remaining flags. The other staging tables still contain flagged rows, mainly due to known data quality issues such as unmatched references, missing payment methods, duplicate IDs, suspicious quantities, zero prices, and return-related business-rule issues. These rows are preserved in staging so they can be reviewed or filtered intentionally in downstream modeling.

## 6. Check Date Columns Converted Correctly

**Purpose:** Confirm that date columns were successfully converted from text to DATE in all staging tables. A NULL date means the conversion failed or the value was invalid.

```sql
SELECT 'products launch_date' AS check_name, COUNT(*) FILTER (WHERE launch_date IS NULL) AS null_dates FROM stg.stg_products
UNION ALL
SELECT 'returns return_date', COUNT(*) FILTER (WHERE return_date IS NULL) FROM stg.stg_returns
UNION ALL
SELECT 'customers registration_date', COUNT(*) FILTER (WHERE registration_date IS NULL) FROM stg.stg_customers
UNION ALL
SELECT 'campaigns campaign_date', COUNT(*) FILTER (WHERE campaign_date IS NULL) FROM stg.stg_marketing_campaigns
UNION ALL
SELECT 'payments payment_date', COUNT(*) FILTER (WHERE payment_date IS NULL) FROM stg.stg_payments
UNION ALL
SELECT 'orders order_date', COUNT(*) FILTER (WHERE order_date IS NULL) FROM stg.stg_orders;
```

**Result:**

| check_name                    | null_dates |
| ----------------------------- | ---------- |
| products launch_date          | 0          |
| returns return_date           | 0          |
| customers registration_date   | 883        |
| campaigns campaign_date       | 0          |
| payments payment_date         | 0          |
| orders order_date             | 0          |

**Interpretation:** Date conversion was successful for products, returns, campaigns, payments, and orders. The only remaining date issue is `customers.registration_date`, where 883 records are still null after cleaning.



## 7. Marketing Campaign ID Grain Issue

### Check purpose

The purpose of this check is to understand whether `campaign_id` represents a real marketing campaign or a single marketing interaction/touchpoint.

This matters because the meaning of an ID decides where it should be used in the data model. A real campaign ID would belong in `dim_marketing_campaigns`. A touchpoint ID belongs in the marketing fact table.


### SQL check

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT campaign_id) AS distinct_campaign_ids,
    COUNT(DISTINCT campaign_name) AS distinct_campaign_names,
    COUNT(DISTINCT CONCAT_WS('|', campaign_name, channel)) AS distinct_campaign_channel_combinations
FROM stg.stg_marketing_campaigns;
```

**Result:**

| metric                                      | value  |
|---------------------------------------------|--------|
| total_rows                                  | 12,000 |
| distinct_campaign_ids                       | 12,000 |
| distinct_campaign_names                     | 14     |
| distinct_campaign_channel_combinations      | 98     |

**Interpretation:** The result shows that `campaign_id` is unique for every row. Therefore, it does not represent a reusable campaign identifier, but rather a marketing touchpoint or interaction ID.

The actual campaign dimension is better represented by the combination of:

```text
campaign_name + channel
```


### Severity

**Medium**

This issue does not make the data unusable, but it affects the data model design. If `campaign_id` were used directly as the campaign dimension key, the dimension table would contain 12,000 rows instead of around 98 campaign-channel combinations.

That would make the dimension too detailed and would hide the real analytical level of marketing campaigns.

### Cleaning decision

The raw column name `campaign_id` was kept unchanged in the raw table.

In the staging layer, `campaign_id` should be renamed to:

```text
marketing_touchpoint_id
```

This makes the meaning of the column clearer.

The campaign dimension should not use `marketing_touchpoint_id` as its business key. Instead, `dim_marketing_campaigns` should be created from distinct combinations of:

```text
campaign_name
channel
```

The future marketing fact table should keep `marketing_touchpoint_id` as a degenerate identifier and link to:

```text
customer_key
campaign_key
date_key
```

### Updated modelling decision

```text
dim_marketing_campaigns
- campaign_key
- campaign_name
- channel
```


fact_marketing_touchpoints
- marketing_touchpoint_id
- customer_key
- campaign_key
- date_key
- clicked
- converted

## 8. Marketing Campaign Missing Value Check

### Purpose

The purpose of this check is to verify whether the marketing campaign data contains missing values in the key descriptive campaign columns.

This check is important before creating `dim_marketing_campaigns`, because the campaign dimension is created at the following grain:

```text
campaign_name + channel
```

If `campaign_name` or `channel` is missing, the affected rows may need to be mapped to an Unknown Campaign member in the dimension table.

### SQL

```sql
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

FROM stg.stg_marketing_campaigns;
```

### Result

| metric                        |  value |
| ----------------------------- | -----: |
| total_rows                    | 12,000 |
| missing_campaign_name         |      0 |
| missing_channel               |      0 |
| rows_needing_unknown_campaign |      0 |

### Finding

No missing campaign names or channels were found in `stg.stg_marketing_campaigns`.

This means that the current data does not require an Unknown Campaign fallback row for missing campaign information.

However, the Unknown Campaign member can still be created later in `dim_marketing_campaigns` as a defensive modelling decision, so future unmatched or missing campaign values can still be loaded into the fact table without breaking the model.


## 9. Relationship and Business-rule validation checks

After cleaning the raw tables and storing them in the staging layer, relationship and business-rule validation checks were performed.

The goal of this validation step is to confirm whether the cleaned staging tables can be safely used for data modelling and analysis.

The main focus of this validation file is:

* referential integrity between staging tables
* orphan records
* ghost product references
* affected row counts
* affected revenue or payment impact
* modelling decisions for the mart layer

---

### 1. Referential Integrity Overview

The referential integrity results are documented in **Section 3** (including the full SQL and methodology). The sub-sections below investigate each issue individually.

---

### 2. Order Items Without Matching Product

### Check purpose

This check identifies order item records where the `product_id` does not exist in the cleaned product table.

This means the transaction row exists, but the product master data is missing.

### SQL check: count and row percentage

```sql
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
```

### Result

| Metric                | Value |
| --------------------- | ----: |
| ghost_order_item_rows |   452 |
| ghost_product_ids     |   452 |
| ghost_row_percentage  | 0.60% |

### SQL check: revenue impact

```sql
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
```

### Result

| Metric                      |      Value |
| --------------------------- | ---------: |
| ghost_rows                  |        452 |
| affected_gross_revenue      | 195,479.41 |
| affected_revenue_percentage |      0.62% |

### Interpretation

452 order item rows reference product IDs that do not exist in the product master table.

This represents 0.60% of all order item rows and 0.62% of gross revenue.

The issue has a low overall impact on sales totals. However, it affects product-level analysis because product name, category, subcategory, and brand cannot be joined for these records.

### Severity

Medium

### Decision

The affected order item rows are kept because they may still contain valid transaction information such as:

* order ID
* quantity
* unit price
* discount
* revenue

The rows are flagged as missing product master data.

In the mart layer, they will be mapped to an `Unknown Product` member, for example:

```text
product_key = -1
```

These rows can be included in total revenue analysis, but should be excluded or clearly grouped in detailed product, category, brand, and margin analysis.

### Ghost Product Source Check

A source check was performed to verify whether the ghost product IDs existed in the original raw product table before cleaning.

| Metric | Value |
|---|---:|
| ghost_product_ids | 452 |
| found_in_raw_products | 0 |
| found_in_stg_products | 0 |

The result shows that none of the ghost product IDs exist in either the raw product table or the cleaned staging product table.

This confirms that the ghost product issue was not caused by the cleaning process.  
The affected product IDs were already missing from the original product master data.

Therefore, these records are treated as missing product master data / invalid product references.  
They are kept and flagged, but not corrected manually.

Confirmed at the mart layer: all 452 `ghost_product_flag` rows in `mart.fact_order_items` resolve to `product_key = -1` (category = "Unknown"), totaling €166,115.62 in `line_total` — this revenue cannot be attributed to any category and must stay excluded from category-level breakdowns.

---

### 3. Orders Without Matching Customer

### Check purpose

This check identifies order records where the `customer_id` does not exist in the cleaned customer table.

This means the order exists, but the customer master data is missing.

### SQL check: count and row percentage

```sql
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
```

### Result

| Metric                  | Value |
| ----------------------- | ----: |
| orders_without_customer |   248 |
| order_percentage        | 0.80% |

### SQL check: revenue impact

```sql
SELECT
    COUNT(DISTINCT o.order_id) AS orders_without_customer,
    ROUND(SUM(oi.quantity_capped * oi.unit_price), 2) AS affected_gross_revenue,
    ROUND(
        SUM(oi.quantity_capped * oi.unit_price) * 100.0
        / (
            SELECT SUM(quantity_capped * unit_price)
            FROM stg.stg_order_items
        ),
        2
    ) AS affected_revenue_percentage
FROM stg.stg_orders o
LEFT JOIN stg.stg_customers c
    ON o.customer_id = c.customer_id
LEFT JOIN stg.stg_order_items oi
    ON o.order_id = oi.order_id
WHERE c.customer_id IS NULL;
```

### Result

| Metric                      |      Value |
| --------------------------- | ---------: |
| orders_without_customer     |        248 |
| affected_gross_revenue      | 528,467.57 |
| affected_revenue_percentage |      1.68% |

### Interpretation

248 orders reference customer IDs that do not exist in the cleaned customer table.

This represents 0.80% of all orders and 1.68% of gross revenue.

The issue has a limited overall impact on sales totals, but it affects customer-level analysis because customer attributes cannot be joined for these records.

Affected customer attributes include:

* country
* loyalty status
* gender
* registration date
* customer segmentation information

### Severity

Medium

### Decision

The affected orders are kept because they may still represent valid transactions.

The rows are flagged as missing customer master data.

In the mart layer, they will be mapped to an `Unknown Customer` member, for example:

```text
customer_key = -1
```

These rows can be included in total revenue analysis, but should be excluded or clearly grouped in customer segmentation, loyalty analysis, and customer-level analysis.

---

### 4. Payments Without Matching Order

### Check purpose

This check identifies payment records where the `order_id` does not exist in the cleaned order table.

This means the payment exists, but it cannot be connected to a valid order.

### SQL check: count and row percentage

```sql
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
```

### Result

| Metric                 | Value |
| ---------------------- | ----: |
| payments_without_order |   220 |
| payment_percentage     | 0.70% |

### SQL check: payment amount impact

```sql
SELECT
    COUNT(*) AS payments_without_order,
    ROUND(SUM(payment_amount), 2) AS affected_payment_amount,
    ROUND(
        SUM(payment_amount) * 100.0
        / (
            SELECT SUM(payment_amount)
            FROM stg.stg_payments
        ),
        2
    ) AS affected_payment_percentage
FROM stg.stg_payments p
LEFT JOIN stg.stg_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;
```

### Result

| Metric                      |     Value |
| --------------------------- | --------: |
| payments_without_order      |       220 |
| affected_payment_amount     | 68,063.95 |
| affected_payment_percentage |     0.71% |

### Interpretation

220 payment records reference order IDs that do not exist in the cleaned order table.

This represents 0.70% of all payment records and 0.71% of total payment amount.

The overall numeric impact is low. However, these records cannot be reliably connected to:

* customer
* product
* order date
* sales channel
* shipping method

Because the related order record is missing, these payments cannot be safely used in the main sales model.

### Severity

Medium

### Decision

The affected payment records are kept in the staging layer and flagged as missing order references.

They will be excluded from the main sales mart and used only for payment quality or reconciliation checks.

---

### 5. Returns Without Matching Order

### Check purpose

This check identifies return records where the `order_id` does not exist in the cleaned order table.

This means the return exists, but the original order cannot be found.

### SQL check: count and row percentage

```sql
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
```

### Result

| Metric                | Value |
| --------------------- | ----: |
| returns_without_order |    60 |
| return_percentage     | 0.98% |

### Interpretation

60 return records reference order IDs that do not exist in the cleaned order table.

This represents 0.98% of all return records.

The overall row-level impact is low. However, these records cannot be reliably connected to the original order.

This affects analysis such as:

* return rate
* refund analysis by order
* customer return behavior
* return reason by original sale
* product return rate connected to sales

### Severity

Medium

### Decision

The affected return records are kept in the staging layer and flagged as missing order references.

They will be excluded from return-rate analysis because the original order is missing.

They may still be used for return data quality reporting.

---

### 6. Returns Without Matching Product

### Check purpose

This check identifies return records where the `product_id` does not exist in the cleaned product table.

This means the return exists, but the product master data is missing.

### SQL check: count and row percentage

```sql
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
```

### Result

| Metric                     |  Value |
| -------------------------- | -----: |
| returns_without_product    |  1,835 |
| missing_return_product_ids |    445 |
| return_row_percentage      | 30.10% |

### Interpretation

1,835 return records reference product IDs that do not exist in the cleaned product table.

This represents 30.10% of all return records.

This is a high-impact issue because almost one third of the return table cannot be connected to valid product master data.

This affects analysis such as:

* return rate by product
* return rate by category
* return reason by brand
* most returned products
* product quality analysis

### Severity

High

### Decision

See sections 9.7–9.10 for the full investigation (pattern check, frequency analysis, correction test) and final decision on how these records are handled.

---

### 7. Missing Return Product Pattern Check

### Check purpose

This check identifies whether the missing return products are caused by null values, malformed values, or a specific ghost product pattern.

### SQL check

```sql
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
GROUP BY
    CASE
        WHEN r.product_id LIKE 'PROD-GHOST-%' THEN 'ghost product id'
        WHEN r.product_id IS NULL THEN 'missing product_id'
        ELSE 'other missing product reference'
    END
ORDER BY row_count DESC;
```

### Result

| Missing Product Type | Row Count |
| -------------------- | --------: |
| ghost product id     |     1,835 |

### Interpretation

All missing return product references follow the `PROD-GHOST-*` pattern.

This means the issue is not caused by:

* null product IDs
* empty product IDs
* random malformed product IDs
* simple text formatting issues

The issue is caused by ghost product references.

---

### 8. Most Frequent Ghost Product IDs in Returns

### Check purpose

This check identifies whether the return product issue is caused by a few repeated ghost product IDs or spread across many ghost product IDs.

### SQL check

```sql
SELECT
    r.product_id,
    COUNT(*) AS return_count
FROM stg.stg_returns r
LEFT JOIN stg.stg_products p
    ON r.product_id = p.product_id
WHERE p.product_id IS NULL
GROUP BY r.product_id
ORDER BY return_count DESC
LIMIT 20;
```

### Example result

| product_id     | return_count |
| -------------- | -----------: |
| PROD-GHOST-299 |           10 |
| PROD-GHOST-62  |           10 |
| PROD-GHOST-248 |           10 |
| PROD-GHOST-203 |            9 |
| PROD-GHOST-117 |            9 |
| PROD-GHOST-367 |            9 |
| PROD-GHOST-399 |            9 |
| PROD-GHOST-155 |            9 |
| PROD-GHOST-292 |            9 |

### Interpretation

The most frequent ghost product IDs appear around 9 to 10 times each.

This means the issue is spread across many ghost product IDs rather than being caused by one single repeated invalid product ID.

---

### 9. Ghost Returns Matched to Original Order Items

### Check purpose

This check tests whether ghost-product return records can still be verified against the original order item.

A return is more reliable if the same `order_id` and `product_id` exist in `stg_order_items`.

### SQL check

```sql
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
```

### Result

| Metric                    | Value |
| ------------------------- | ----: |
| returns_without_product   | 1,835 |
| matched_to_order_item     |     0 |
| not_matched_to_order_item | 1,835 |

### Interpretation

None of the 1,835 ghost-product return records match the original order item by both `order_id` and `product_id`.

This means the returned product cannot be verified against the original sold product.

The issue is therefore more serious than only missing product master data.

It is also a return transaction consistency issue.

---

### 10. Ghost Product Correction Test

### Check purpose

This check tests whether `PROD-GHOST-*` values can be safely transformed into normal product IDs.

Two possible correction formats were tested:

```text
PROD-GHOST-117 → PROD-117
PROD-GHOST-117 → PROD-000117
```

The goal was to check whether removing the `GHOST` part would create valid product IDs.

### SQL check

```sql
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
```

### Result

| Metric                    | Value |
| ------------------------- | ----: |
| ghost_return_rows         | 1,835 |
| matched_plain_product_id  |     0 |
| matched_padded_product_id |     0 |

### Interpretation

The correction test returned 0 matches for both candidate formats.

Therefore, the ghost product IDs cannot be safely corrected into existing product IDs.

The values should not be transformed by simply removing `GHOST`.

### Decision

The original ghost product IDs are kept.

The affected rows are flagged and treated as invalid product references.

They should not be used for detailed product-level return analysis.

---

### 11. Final Validation Summary

| Issue                       | Count | Percentage |     Financial Impact | Severity | Decision                                                                          |
| --------------------------- | ----: | ---------: | -------------------: | -------- | --------------------------------------------------------------------------------- |
| order_items without product |   452 |      0.60% |  0.62% gross revenue | Medium   | Keep, flag, map to Unknown Product                                                |
| orders without customer     |   248 |      0.80% |  1.68% gross revenue | Medium   | Keep, flag, map to Unknown Customer                                               |
| payments without order      |   220 |      0.70% | 0.71% payment amount | Medium   | Keep in staging, flag, exclude from main sales mart                               |
| returns without order       |    60 |      0.98% |          Not checked | Medium   | Keep in staging, flag, exclude from return-rate analysis                          |
| returns without product     | 1,835 |     30.10% |          Not checked | High     | Keep, flag, map to Unknown Product, exclude from detailed product return analysis |
| order_items without order   |     0 |      0.00% |            No impact | None     | No action needed                                                                  |

---

### 12. Modelling Implications

The validation results have direct impact on the mart layer.

### Unknown Product

Some sales and return records reference products that do not exist in the product master table.

In the mart layer, these records should be mapped to an `Unknown Product` member.

Example:

```text
product_key = -1
product_id = UNKNOWN
product_name = Unknown Product
category = Unknown Category
brand = Unknown Brand
```

### Unknown Customer

Some orders reference customers that do not exist in the customer master table.

In the mart layer, these records should be mapped to an `Unknown Customer` member.

Example:

```text
customer_key = -1
customer_id = UNKNOWN
customer_name = Unknown Customer
```

### Sales Analysis Rule

Rows with missing product or customer references can still be used for total-level sales analysis if the transaction itself is valid.

However, they should be clearly grouped or excluded in detailed analysis.

### Return Analysis Rule

Return records with invalid product references should not be used for product-level return-rate analysis.

They may be used for general return counts or data quality reporting, but not for reliable product, category, or brand return insights.

### Payment Analysis Rule

Payments without matching orders should be kept in staging but excluded from the main sales mart because they cannot be safely connected to the original transaction.

---

### 13. Final Decision

The validation checks show that the cleaned staging layer is mostly usable for modelling, but some relationship issues remain.

The main modelling approach is:

* keep valid transaction records
* do not guess missing master data
* do not delete records silently
* preserve original IDs
* add quality flags
* use `Unknown` dimension members where appropriate
* exclude unreliable records from detailed analysis

This keeps the analysis honest while preserving useful business information.

---

## 10. Extreme Order Item Quantities (Corrupted Data Recovery)

**Purpose:** Confirm scope and fix for order items with implausible `quantity` values (up to 1996).

```sql
SELECT
    COUNT(*) AS extreme_rows,
    COUNT(*) FILTER (
        WHERE ROUND(line_total_original / NULLIF(unit_price*(1-discount),0)) BETWEEN 1 AND 5
          AND ABS(line_total_original / NULLIF(unit_price*(1-discount),0)
                  - ROUND(line_total_original / NULLIF(unit_price*(1-discount),0))) < 0.02
    ) AS cleanly_recoverable
FROM stg.stg_order_items
WHERE quantity_original > 99;
```

**Result:**

| Metric | Value |
|---|---:|
| extreme_rows | 228 (0.30% of rows) |
| cleanly_recoverable | 216 |

**Root cause:** confirmed in `scripts/generate_retail_dataset.py` — the generator computes `line_total` from a real quantity (1-5) first, then overwrites `quantity` with a random 500-2000 value on ~0.3% of rows. `line_total_original` still reflects the true quantity.

**Interpretation:** 216/228 rows back-solve to a clean integer 1-5 from `line_total_original`, confirming that value is trustworthy. The other 11 don't resolve cleanly (implied quantity >5, impossible) — these also hit an independent "wrong total" corruption rule, so neither field is fully trustworthy for them; back-solved value used as a clamped (1-5) best estimate.

**Revenue impact:** old recalculated total for these 228 rows: €2,369,765.72. Corrected (trusting `line_total_original`): €71,081.14. Mart-level Gross Sales Revenue: €24,832,582.53 → €22,684,205.36.

**Severity:** High — affected `Units Sold`, `COGS`, `Gross Profit`/`Margin`, and (via the recalculation bug) Gross Sales Revenue itself.

**Decision:**

* `quantity_capped` now back-solves from `line_total_original` (clamped 1-5) instead of capping the corrupted value; `line_total_clean` trusts `line_total_original` for these rows.
* The 11 non-clean rows need no new flag — they already surface via `line_total_mismatch_flag = TRUE`.
* Separate bug fixed in `fact_order_items.sql`: it was selecting raw `quantity` instead of `quantity_capped`.
* **Follow-up:** `docs/business_rules/BUSINESS_METADATA.md`'s revenue validation table predates this fix and needs re-running.


