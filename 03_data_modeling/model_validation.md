# Model Validation

This document records validation checks run after creating the dimension and fact tables. The goal is to confirm that the mart layer was built correctly and is ready for analysis.

---

## 1. Dimension Table Row Counts

**Purpose:** Confirm that all dimension tables were created and contain the expected number of rows, including the unknown fallback row.

```sql
SELECT 'dim_customer'            AS table_name, COUNT(*) AS row_count FROM mart.dim_customer
UNION ALL
SELECT 'dim_product',                           COUNT(*)              FROM mart.dim_product
UNION ALL
SELECT 'dim_date',                              COUNT(*)              FROM mart.dim_date
UNION ALL
SELECT 'dim_payment',                           COUNT(*)              FROM mart.dim_payment
UNION ALL
SELECT 'dim_return_reason',                     COUNT(*)              FROM mart.dim_return_reason
UNION ALL
SELECT 'dim_marketing_campaigns',               COUNT(*)              FROM mart.dim_marketing_campaigns;
```

**Result:**

| Table | Row count | Notes |
|---|---|---|
| `dim_customer` | 8,365 | 8,364 real customers + 1 unknown fallback row (-1) |
| `dim_product` | 1,091 | 1,090 real products + 1 unknown fallback row (-1) |
| `dim_date` | 1,467 | Calendar days covering full date range across all four fact sources |
| `dim_payment` | 31,466 | 31,465 real payments + 1 unknown fallback row (-1) |
| `dim_return_reason` | 9 | 9 unique return reasons — no unknown fallback row by design |
| `dim_marketing_campaigns` | 99 | 98 campaign-channel combinations + 1 unknown fallback row (-1) |

**Interpretation:** All six dimension tables exist and contain data. Row counts match expected staging source counts plus one unknown fallback row where applicable. `dim_return_reason` correctly has no fallback row — NULL reasons are handled inline during staging.

---

## 2. Unknown Fallback Row Confirmation

**Purpose:** Confirm that the `-1` unknown fallback row exists in every dimension that uses it.

```sql
SELECT 'dim_customer'          AS dim_table, customer_key  AS key FROM mart.dim_customer          WHERE customer_key  = -1
UNION ALL
SELECT 'dim_product',                        product_key          FROM mart.dim_product           WHERE product_key   = -1
UNION ALL
SELECT 'dim_payment',                        payment_key          FROM mart.dim_payment           WHERE payment_key   = -1
UNION ALL
SELECT 'dim_marketing_campaigns',            campaign_key         FROM mart.dim_marketing_campaigns WHERE campaign_key = -1;
```

**Result:**

| Dim table | Key found? |
|---|---|
| `dim_customer` | Yes (-1) |
| `dim_product` | Yes (-1) |
| `dim_payment` | Yes (-1) |
| `dim_marketing_campaigns` | Yes (-1) |

**Interpretation:** All four dimensions that require an unknown fallback row have it correctly in place at key = -1.

---

## 3. Dimension Business Key Uniqueness

**Purpose:** Confirm that every dimension table has exactly one row per business key after loading.

```sql
SELECT 'dim_customer' AS table_name,
    COUNT(*) AS total_rows, COUNT(DISTINCT customer_id) AS distinct_keys
FROM mart.dim_customer
UNION ALL
SELECT 'dim_product',
    COUNT(*), COUNT(DISTINCT product_id)
FROM mart.dim_product
UNION ALL
SELECT 'dim_date',
    COUNT(*), COUNT(DISTINCT date_key)
FROM mart.dim_date
UNION ALL
SELECT 'dim_payment',
    COUNT(*), COUNT(DISTINCT payment_id)
FROM mart.dim_payment
UNION ALL
SELECT 'dim_return_reason',
    COUNT(*), COUNT(DISTINCT return_reason)
FROM mart.dim_return_reason
UNION ALL
SELECT 'dim_marketing_campaigns',
    COUNT(*), COUNT(DISTINCT campaign_name || '|' || channel)
FROM mart.dim_marketing_campaigns;
```

**Result:**

| Table | Total rows | Distinct keys | Match? |
|---|---|---|---|
| `dim_customer` | 8,365 | 8,365 | Yes |
| `dim_product` | 1,091 | 1,091 | Yes |
| `dim_date` | 1,467 | 1,467 | Yes |
| `dim_payment` | 31,466 | 31,466 | Yes |
| `dim_return_reason` | 9 | 9 | Yes |
| `dim_marketing_campaigns` | 99 | 99 | Yes |

**Interpretation:** All six dimension tables are at the correct grain — no duplicate business keys exist in any table.

---

## 4. Fact Table Row Counts

**Purpose:** Confirm that all four fact tables were created and that row counts match the source staging tables. Differences are expected only if rows were intentionally filtered.

```sql
SELECT 'fact_order_items'           AS fact_table, COUNT(*) AS fact_rows FROM mart.fact_order_items
UNION ALL
SELECT 'fact_payments',                            COUNT(*)               FROM mart.fact_payments
UNION ALL
SELECT 'fact_returns',                             COUNT(*)               FROM mart.fact_returns
UNION ALL
SELECT 'fact_marketing_touchpoints',               COUNT(*)               FROM mart.fact_marketing_touchpoints;
```

**Result:**

| Fact table | Fact rows | Staging rows | Difference |
|---|---|---|---|
| `fact_order_items` | 75,473 | 75,473 | 0 |
| `fact_payments` | 31,465 | 31,465 | 0 |
| `fact_returns` | 6,097 | 6,097 | 0 |
| `fact_marketing_touchpoints` | 12,000 | 12,000 | 0 |

**Interpretation:** All four fact tables loaded completely. No rows were lost — every staging record has a corresponding row in the mart layer.

---

## 5. Unknown Member Counts

**Purpose:** Confirm how many fact rows could not be matched to a real dimension record and were mapped to the `-1` unknown fallback. High counts indicate data quality issues worth investigating.

```sql
-- fact_order_items
SELECT
    COUNT(*)                                                     AS total_rows,
    SUM(CASE WHEN customer_key    = -1   THEN 1 ELSE 0 END)     AS unknown_customers,
    SUM(CASE WHEN product_key     = -1   THEN 1 ELSE 0 END)     AS unknown_products,
    SUM(CASE WHEN order_date_key IS NULL THEN 1 ELSE 0 END)     AS missing_date_key
FROM mart.fact_order_items;

-- fact_payments
SELECT
    COUNT(*)                                                     AS total_rows,
    SUM(CASE WHEN customer_key     = -1   THEN 1 ELSE 0 END)    AS unknown_customers,
    SUM(CASE WHEN payment_key      = -1   THEN 1 ELSE 0 END)    AS unknown_payments,
    SUM(CASE WHEN payment_date_key IS NULL THEN 1 ELSE 0 END)   AS missing_date_key
FROM mart.fact_payments;

-- fact_returns
SELECT
    COUNT(*)                                                     AS total_rows,
    SUM(CASE WHEN customer_key       = -1   THEN 1 ELSE 0 END)  AS unknown_customers,
    SUM(CASE WHEN product_key        = -1   THEN 1 ELSE 0 END)  AS unknown_products,
    SUM(CASE WHEN return_reason_key IS NULL THEN 1 ELSE 0 END)  AS missing_reason_key,
    SUM(CASE WHEN return_date_key   IS NULL THEN 1 ELSE 0 END)  AS missing_date_key
FROM mart.fact_returns;

-- fact_marketing_touchpoints
SELECT
    COUNT(*)                                                     AS total_rows,
    SUM(CASE WHEN customer_key      = -1   THEN 1 ELSE 0 END)   AS unknown_customers,
    SUM(CASE WHEN campaign_key      = -1   THEN 1 ELSE 0 END)   AS unknown_campaigns,
    SUM(CASE WHEN campaign_date_key IS NULL THEN 1 ELSE 0 END)  AS missing_date_key
FROM mart.fact_marketing_touchpoints;
```

**Result:**

| Fact table | Total rows | Unknown customers | Unknown products | Unknown campaigns | Unknown payments | Missing date key | Missing reason key |
|---|---|---|---|---|---|---|---|
| `fact_order_items` | 75,473 | 1,222 | 452 | N/A | N/A | 0 | N/A |
| `fact_payments` | 31,465 | 707 | N/A | N/A | 0 | 0 | N/A |
| `fact_returns` | 6,097 | 242 | 1,835 | N/A | N/A | 0 | 0 |
| `fact_marketing_touchpoints` | 12,000 | 0 | N/A | 0 | N/A | 0 | N/A |

**Interpretation:**

- `fact_order_items`: 1,222 rows (1.6%) have unknown customers; 452 rows (0.6%) have unknown products. No missing date keys.
- `fact_payments`: 707 rows (2.2%) have unknown customers — payments linked to orders with no matching customer. No unknown payment keys or missing date keys, meaning all payment transactions resolved correctly to `dim_payment`.
- `fact_returns`: 242 rows (4.0%) have unknown customers. 1,835 rows (30.1%) have unknown products — the most significant data quality issue in the model. All return reasons resolved (0 missing reason keys), and all return dates resolved (0 missing date keys).
- `fact_marketing_touchpoints`: Completely clean — all customers, campaigns, and dates resolved with zero unknowns.

---

## 6. Measure Sanity Checks

**Purpose:** Confirm that key measures contain valid values — no unexpected NULLs, no negative amounts, and totals are in a plausible range.

```sql
-- fact_order_items: revenue totals and NULL check
SELECT
    SUM(line_total)                                              AS total_revenue,
    SUM(CASE WHEN line_total < 0     THEN 1 ELSE 0 END)        AS negative_line_totals,
    SUM(CASE WHEN line_total IS NULL THEN 1 ELSE 0 END)        AS null_line_totals,
    SUM(CASE WHEN ghost_product_flag  = TRUE THEN 1 ELSE 0 END) AS ghost_product_rows
FROM mart.fact_order_items;

-- fact_payments: total amount by payment status
SELECT
    dp.payment_status,
    COUNT(*)               AS payment_count,
    SUM(fp.payment_amount) AS total_amount
FROM mart.fact_payments fp
JOIN mart.dim_payment dp ON fp.payment_key = dp.payment_key
GROUP BY dp.payment_status
ORDER BY total_amount DESC;

-- fact_returns: refund totals and ghost record counts
SELECT
    SUM(refund_amount)                                          AS total_refunds,
    SUM(CASE WHEN refund_amount IS NULL THEN 1 ELSE 0 END)     AS null_refunds,
    SUM(CASE WHEN ghost_product_flag    THEN 1 ELSE 0 END)     AS ghost_product_rows,
    SUM(CASE WHEN ghost_order_flag      THEN 1 ELSE 0 END)     AS ghost_order_rows
FROM mart.fact_returns;

-- fact_marketing_touchpoints: clicks, conversions, conversion rate
SELECT
    SUM(clicked)                                                AS total_clicks,
    SUM(converted)                                              AS total_conversions,
    ROUND(SUM(converted)::NUMERIC / NULLIF(SUM(clicked), 0) * 100, 2) AS conversion_rate_pct,
    SUM(CASE WHEN ghost_customer_flag          THEN 1 ELSE 0 END) AS ghost_customer_rows,
    SUM(CASE WHEN converted_without_click_flag THEN 1 ELSE 0 END) AS invalid_conversion_rows
FROM mart.fact_marketing_touchpoints;
```

**Result:**

*fact_order_items*

| Total revenue | Negative line totals | NULL line totals | Ghost product rows |
|---|---|---|---|
| €26,661,109.20 | 0 | 0 | 452 |

*fact_payments by payment status*

| Payment status | Payment count | Total amount |
|---|---|---|
| Paid | 22,178 | €6,782,387.87 |
| Pending | 3,182 | €969,338.21 |
| Refunded | 3,041 | €922,493.93 |
| Failed | 1,518 | €461,629.29 |
| Partially Refunded | 1,546 | €454,759.21 |

*fact_returns*

| Total refunds | NULL refunds | Ghost product rows | Ghost order rows |
|---|---|---|---|
| €914,199.22 | 0 | 1,835 | 0 |

*fact_marketing_touchpoints*

| Total clicks | Total conversions | Conversion rate % | Ghost customer rows | Invalid conversion rows |
|---|---|---|---|---|
| 3,619 | 733 | 20.25% | 0 | 0 |

**Interpretation:**

- `fact_order_items`: No negative or NULL line totals — measures are clean. Total revenue of €26.7M across all line items including ghost product rows.
- `fact_payments`: Payment statuses are as expected. Only 70.5% of payments (22,178) are Paid — the rest are pending, failed, or refunded and should be excluded from realized revenue analysis.
- `fact_returns`: 1,835 out of 6,097 return rows (30.1%) are ghost product rows — the returned product ID does not exist in the product master. These returns have a valid refund amount but cannot be attributed to any product category. This is a significant data quality finding that should be considered when calculating return rates by category. No ghost order rows, meaning all returns can be traced back to a valid order.
- `fact_marketing_touchpoints`: Completely clean — no ghost customers and no invalid conversions. 20.25% conversion rate among those who clicked.

---

## 7. Duplicate Customer Identity Resolution (2026-07-03)

**Purpose:** Confirm that duplicate customer identities (same real person registered under two different `customer_id` values) are correctly flagged and resolved to a canonical key after running `dim_customer_duplicate_resolution.sql`.

```sql
-- Duplicate-email groups and match strength
WITH dup_emails AS (
    SELECT email
    FROM mart.dim_customer
    WHERE is_unknown_customer = false AND email IS NOT NULL
    GROUP BY email
    HAVING COUNT(*) > 1
),
dup_rows AS (
    SELECT dc.* FROM mart.dim_customer dc JOIN dup_emails de ON dc.email = de.email
),
group_stats AS (
    SELECT email, COUNT(*) AS n_rows,
        COUNT(DISTINCT full_name) AS n_distinct_names,
        COUNT(DISTINCT phone) AS n_distinct_phones,
        COUNT(DISTINCT registration_date) AS n_distinct_reg_dates
    FROM dup_rows
    GROUP BY email
)
SELECT COUNT(*) AS total_dup_groups,
    SUM(CASE WHEN n_distinct_names = 1 THEN 1 ELSE 0 END) AS same_name_groups,
    SUM(CASE WHEN n_distinct_phones = 1 THEN 1 ELSE 0 END) AS same_phone_groups,
    SUM(CASE WHEN n_distinct_reg_dates = 1 THEN 1 ELSE 0 END) AS same_reg_date_groups
FROM group_stats;

-- Post-resolution check: flag counts and canonical key coverage
SELECT
    COUNT(*) FILTER (WHERE duplicate_customer_flag = true)      AS flagged_duplicates,
    COUNT(*) FILTER (WHERE canonical_customer_key IS NULL
                      AND is_unknown_customer = false)          AS missing_canonical_key
FROM mart.dim_customer;

-- Corrected vs. uncorrected average revenue per customer
SELECT
    ROUND(SUM(foi.line_total) / COUNT(DISTINCT foi.customer_key), 2)        AS uncorrected_avg_revenue,
    ROUND(SUM(foi.line_total) / COUNT(DISTINCT dc.canonical_customer_key), 2) AS corrected_avg_revenue
FROM mart.fact_order_items foi
JOIN mart.dim_customer dc ON foi.customer_key = dc.customer_key
WHERE dc.is_unknown_customer = false;
```

**Result:**

| Check | Result |
|---|---:|
| Total duplicate-email groups | 148 |
| Group size | All size 2 (296 rows affected, ~3.5% of 8,364 real customers) |
| Groups also matching `full_name` | 148 / 148 (100%) |
| Groups also matching `phone` | 126 / 148 (85%) |
| Groups also matching `registration_date` | 126 / 148 (85%) |
| Groups with orders placed under both keys | 135 / 148 (91%) |
| Avg combined revenue per real person (both keys) | €5,663.07 |
| `flagged_duplicates` after resolution script | 148 (confirmed) |
| `missing_canonical_key` after resolution script | 0 (confirmed) |
| `broken_canonical_links` (a duplicate pointing to another duplicate) | 0 (confirmed) |
| Customer count: uncorrected (`customer_key`) vs. corrected (`canonical_customer_key`) | 8,166 → 8,031 (−135, exactly matches the 135/148 groups with orders under both keys) |
| Avg revenue per customer: uncorrected vs. corrected | €3,209.51 → €3,263.46 (+1.7%) |

**Interpretation:** The high match rate on name/phone/registration_date confirms these are genuine duplicate registrations, not coincidental email reuse. 91% of duplicate groups placed orders under both keys, meaning real customer revenue was being split across two records — each half landing inside the normal per-customer revenue range, so the distortion was not visible as an outlier. After running the resolution script, every real customer has a `canonical_customer_key`, and exactly 148 rows are flagged as duplicates (matching the group count, since every group has exactly one non-canonical sibling). The post-run customer count drop of exactly 135 independently confirms the earlier finding, computed a different way. See `model_documentation.md` §4.8 for the full modelling decision and rationale.

**Action for downstream analysis:** Any query computing customer counts, historical CLV, or predicted CLV should `GROUP BY canonical_customer_key` instead of `customer_key` going forward. As of this validation, `04_EDA/nordhome_eda.ipynb` and `05_customer_analysis/customer_ltv_prediction.ipynb` still use `customer_key` and have not yet been updated.

---

## 8. Validation Summary

| Check | Tables covered | Status | Notes |
|---|---|---|---|
| Dimension row counts | All 6 dims | Pass | All counts match expected staging source + unknown fallback rows |
| Unknown fallback row exists | dim_customer, dim_product, dim_payment, dim_marketing_campaigns | Pass | All four confirmed at key = -1 |
| Business key uniqueness | All 6 dims | Pass | No duplicate keys in any dimension table |
| Fact row counts vs staging | All 4 facts | Pass | Zero rows lost across all four fact tables |
| Unknown member counts | All 4 facts | Pass | See section 5 for full breakdown |
| Measure sanity | All 4 facts | Pass | No negative or NULL measures; payment and refund totals are plausible |
| Ghost product flag in fact_returns | fact_returns | Flag | 1,835 rows (30.1%) are ghost products — cannot be attributed to a category |
| Duplicate customer identity resolution (2026-07-03) | dim_customer | Pass (resolved) | 148 customers (3.5%) had duplicate registrations; 91% had revenue split across both keys. Resolved via `duplicate_customer_flag` / `canonical_customer_key`, confirmed by re-running validation post-fix. Downstream notebooks not yet updated to use them |