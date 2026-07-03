# Data Model Documentation

## 1. Goal

The goal of this data model is to create an analysis-ready star schema for sales, customer, product, payment, return, and marketing analysis.

The model is designed to support business questions such as:

- Revenue development over time
- Customer and country performance
- Product and category performance
- Order and payment behaviour
- Return impact on revenue
- Marketing campaign performance and channel attribution

---

## 2. Model Overview

The model follows a star schema pattern with 4 fact tables and 6 dimension tables.
All 4 fact tables share `dim_customer` and `dim_date` as conformed dimensions.

```
                             dim_date
                                ↑
dim_customer ←── fact_order_items ──────────────────→ dim_product
                 (order_status, country,
                  sales_channel, shipping_method
                  denormalized on fact)

dim_customer ←── fact_payments ─────────────────────→ dim_payment
                 (order_status, country,
                  sales_channel denormalized on fact)

dim_customer ←── fact_returns ──────────────────────→ dim_product
                 (order_status, country,              → dim_return_reason
                  sales_channel denormalized on fact)

dim_customer ←── fact_marketing_touchpoints ─────────→ dim_marketing_campaigns
```

### 2.1 Build Order

Tables must be created in this sequence. Each layer depends on the previous one.

1. **Staging layer** (`stg` schema) — run all files in `02_data_cleaning_transformation/`
2. **Dimension tables** (`mart` schema) — run all files in `03_data_modeling/01_dimension_tables/`. Any order within this layer is safe, but `dim_date` must be rebuilt whenever the date range changes.
3. **Fact tables** (`mart` schema) — run in this order:
   - `fact_order_items.sql`
   - `fact_payments.sql`
   - `fact_returns.sql` — `dim_return_reason` must be current before running; rebuilding the dim drops the PK that the fact FK references
   - `fact_marketing_touchpoints.sql` — `stg_marketing_campaigns` must use `marketing_touchpoint_id` (not the original `campaign_id`); rebuild the stg table first if the column is missing

---

## 3. Dimension Tables

| Dimension table | Grain | Description |
|---|---|---|
| `dim_customer` | One row per customer | Demographics, geography, registration info, loyalty status, and data quality flags |
| `dim_product` | One row per product | Product name, category, subcategory, brand, unit cost, list price, and quality status |
| `dim_date` | One row per calendar day | Year, quarter, month, week, day, and weekend flag — generated from the combined date range across all four fact sources |
| `dim_payment` | One row per payment transaction | Payment method, payment status, and payment date |
| `dim_return_reason` | One row per unique return reason | Return reason text and standardized reason category |
| `dim_marketing_campaigns` | One row per campaign-channel combination | Campaign name and channel |

---

## 4. Modelling Decisions

### 4.1 dim_order removed — order attributes denormalized onto fact

A `dim_order` table was considered but removed during modelling review.

In a Kimball star schema, orders are facts (they carry measures: revenue, quantity), not dimensions. Storing them as a separate dimension creates an unnecessary outrigger join on every query.

Instead, order-level descriptive attributes — `order_status`, `country`, `sales_channel`, `shipping_method` — are denormalized directly onto `fact_order_items`, `fact_payments`, and `fact_returns`. These attributes have the same value for every row that belongs to the same order, so denormalization adds no redundancy risk.

`order_id` is retained as a degenerate dimension on each fact table for direct lookup and cross-fact joining without needing a separate table.

### 4.2 Payment split — dim_payment and fact_payments

Payment data is split across a dimension table and a fact table.

`dim_payment` stores descriptive payment attributes: payment method, payment status, and payment date.

`fact_payments` stores the measurable event: payment amount.

This separation keeps measures and descriptors in their correct layers. Payment method and status are used as filter and grouping attributes in analysis (e.g. revenue by payment method, refund rate by method), while payment amount is the metric being aggregated.

### 4.3 Return split — dim_return_reason and fact_returns

Return data is split across a dimension table and a fact table.

`dim_return_reason` is a small lookup table that maps each unique return reason text to a standardized `reason_category` (e.g. 'Delivery issue', 'Product quality', 'Customer preference'). This allows grouping returns by category without repeating the mapping logic in every query.

`fact_returns` stores the actual return event: return date, refund amount, and links to the customer, product, and reason.

`dim_return_reason` has no `-1` unknown fallback row. This is intentional: NULL and blank return reasons are handled inline during the staging INSERT (`COALESCE(NULLIF(TRIM(...), ''), 'Unknown')`), so every return reason in the fact table is guaranteed to find a match in the dimension. The FK is declared nullable as a defensive measure only.

### 4.4 Marketing campaign grain

The raw `campaign_id` column is unique per row (12,000 distinct values for 12,000 rows). It represents an individual customer interaction, not a reusable campaign. It was renamed to `marketing_touchpoint_id` in the staging layer.

`dim_marketing_campaigns` is built at the campaign-channel grain (one row per unique `campaign_name + channel` combination), giving 98 real campaign-channel rows plus one Unknown fallback row.

`fact_marketing_touchpoints` stores one row per touchpoint with `marketing_touchpoint_id` as a degenerate dimension.

This grain keeps the campaign dimension small and analytical, supporting questions like clicks per channel, conversions per campaign, and channel performance comparison.

### 4.5 Date dimension

`dim_date` is generated at day level using GENERATE_SERIES, which ensures every calendar date in the range is present even if no event occurred on that day.

The date key uses YYYYMMDD integer format (e.g. 2024-03-15 → 20240315) for fast joins without string conversion.

**Date range decision:** The range is derived from the MIN and MAX across all four source date columns — `order_date`, `payment_date`, `return_date`, and `campaign_date` — not just orders. This is required because all four fact tables hold a `date_key` FK that must resolve to a row in `dim_date`. Building the range from orders only caused a foreign key violation when campaign dates fell outside the order date range.

### 4.6 Data quality flags on fact tables

Not all staging quality flags are carried into the fact tables. The decision rule is:

> Keep a flag if it changes whether a row belongs in standard reporting or affects which measure value to trust. Remove a flag if the measure is still valid regardless, or if the information is already available from the dimension.

All flags originate in the `stg` layer — they are computed during staging. Only a selected subset are carried into each fact table. Flags not carried are listed in the "Flags removed" table below.

**Flags kept and why:**

| Flag | Table | Reason kept |
|---|---|---|
| `ghost_product_flag` | fact_order_items, fact_returns | Product doesn't exist in the master — revenue and returns cannot be attributed to any category or brand |
| `zero_unit_price_flag` | fact_order_items | A zero unit price produces zero line_total — silently excludes the row from revenue without explanation |
| `line_total_mismatch_flag` | fact_order_items | The raw line_total and the recalculated value disagree — analyst must decide which number to trust |
| `ghost_order_flag` | fact_payments, fact_returns | Order doesn't exist in the master — payment or return cannot be linked to any real transaction |
| `ghost_customer_flag` | fact_marketing_touchpoints | Customer doesn't exist — touchpoint cannot be attributed to any real customer |
| `converted_without_click_flag` | fact_marketing_touchpoints | Conversion recorded with no prior click — the conversion logic itself is invalid for this row |

**Flags removed and why:**

| Flag | Table | Reason removed |
|---|---|---|
| `discount_range_issue_flag` | fact_order_items | The `discount` column is already capped to [0, 1] in staging — the flag describes the original dirty value, not what was loaded |
| `missing_payment_method_flag` | fact_payments | Redundant — detectable as `payment_method IS NULL` directly from `dim_payment` |
| `payment_before_order_flag` | fact_payments | The payment_amount is still valid regardless of date order — this is a timing anomaly, not a measure problem |
| `return_before_order_flag` | fact_returns | The refund_amount is still valid regardless of date order — same reasoning as above |

### 4.7 Age group logic in dim_customer

`age_group` is a derived column in `dim_customer` computed from `birth_year` at load time.

**Analysis year:** Age buckets are calculated against a fixed reference year of **2024** (the latest year present in the dataset), not `CURRENT_DATE`. This ensures the grouping is stable and reproducible regardless of when the table is rebuilt. The reference year is defined once via `CROSS JOIN (SELECT 2024 AS analysis_year) AS p` in the INSERT SELECT and referenced as `p.analysis_year` throughout the CASE expression.

**Buckets:**

| age_group | birth_year range | approx. age in 2024 |
|-----------|-----------------|---------------------|
| Unknown | NULL or < 1900 | — |
| Under 18 | > 2006 | < 18 |
| 18-29 | 1995–2006 | 18–29 |
| 30-39 | 1985–1994 | 30–39 |
| 40-49 | 1975–1984 | 40–49 |
| 50-59 | 1965–1974 | 50–59 |
| 60-69 | 1955–1964 | 60–69 |
| 70+ | ≤ 1954 | 70+ |

**Data quality floor:** `birth_year < 1900` is bucketed as `'Unknown'`. The source data contains 44 rows with placeholder birth years of 1800 (23 rows) and 1890 (21 rows) — clearly invalid data entry defaults, not real dates. This floor removes them from analysis buckets without affecting valid older customers (born 1900+).

**Why 60+ was split into 60-69 and 70+:** The original single `60+` bucket contained 2,090 customers (25% of all real customers), nearly double the size of every other group. Splitting it produces a more balanced distribution for EDA charts and avoids visual skew.

**Resulting distribution (2024 analysis year):**

| age_group | customers | % |
|-----------|-----------|---|
| 18-29 | 1,505 | 18.0% |
| 30-39 | 1,353 | 16.2% |
| 40-49 | 1,319 | 15.8% |
| 50-59 | 1,356 | 16.2% |
| 60-69 | 1,406 | 16.8% |
| 70+ | 684 | 8.2% |
| Unknown | 714 | 8.5% |
| Under 18 | 27 | 0.3% |

---

### 4.8 Duplicate customer identity resolution

Some real customers registered more than once under different `customer_id` values, producing two separate rows (and two `customer_key` values) in `dim_customer` for the same real person.

**Finding (EDA — 2026-07-03):** 148 duplicate-email groups exist among 8,364 real customers (all groups size 2, so 296 rows / ~3.5% of the customer base are affected). Within these groups:
- 100% (148/148) also match on `full_name`
- 85% (126/148) also match on `phone` and `registration_date`

This is strong evidence of true duplicate registrations, not coincidental email reuse.

**Business impact:** 91% of duplicate groups (135/148) placed orders under *both* keys — meaning real revenue is genuinely split across two customer records, not just a harmless duplicate signup. Average combined revenue per real person across their two keys is €5,663 — split in half, each phantom "customer" lands right inside the normal per-customer revenue range (€2,653–2,892 across age groups), so these duplicates do not stand out as outliers. They silently inflate customer counts and silently understate historical/predicted CLV for the affected customers.

**Decision:** Do not merge or delete rows. Instead, two additive columns were added to `dim_customer`:

| Column | Meaning |
|---|---|
| `duplicate_customer_flag` | `TRUE` for the later-registered sibling(s) in a same-email group |
| `canonical_customer_key` | Points to the earliest-registered `customer_key` in the group (or itself, if not a duplicate) |

Canonical row = earliest `registration_date` (`NULLS LAST`), lowest `customer_key` as tiebreaker — consistent with this project's existing dedup convention (`ROW_NUMBER() ... ASC NULLS LAST`, keep first-recorded).

**Reason:** Matches this project's data quality philosophy — detect, count, assess impact, document, and give analysts a way to opt in to the corrected view, rather than silently changing historical figures. Every customer (not just duplicates) gets a `canonical_customer_key`, so it's safe to `GROUP BY canonical_customer_key` universally instead of `customer_key` for any person-level metric (customer counts, historical CLV, predicted CLV).

**Implementation:** `03_data_modeling/01_dimension_tables/dim_customer_duplicate_resolution.sql` — additive `ALTER TABLE ADD COLUMN` + `UPDATE` only. Does not touch `fact_order_items` or its FK to `dim_customer.customer_key`.

**Trade-off / limitation:** Matching is email-based only. A real duplicate that used two different emails would not be caught by this logic. Conversely, if two unrelated people ever shared a household email (not observed in this dataset, but theoretically possible), they would be incorrectly flagged as duplicates. Given the 100% name-match rate found here, this risk is currently theoretical, not observed.

### 4.9 Unknown fallback rows (-1)

Most dimension tables include an unknown fallback row with surrogate key `-1`. This row is used when a fact record cannot be matched to a valid dimension record — for example, ghost customer references in orders, or orphaned product IDs in returns.

Instead of dropping fact rows that fail a dimension join, the model maps them to the unknown member. This keeps fact table counts complete while making data quality issues visible through filters on `is_unknown_customer`, `ghost_product_flag`, etc.

`dim_return_reason` and `dim_date` do not have unknown rows — see sections 4.3 and 4.5 for reasoning.

---

## 5. Fact Tables

### 5.1 `fact_order_items`

**Grain:** one row per order line item.

If one order contains three products, the fact table contains three rows for that order.

| Column | Type | Role |
|---|---|---|
| `fact_order_item_key` | INT | Surrogate PK |
| `order_item_id` | TEXT | Degenerate dimension |
| `order_id` | TEXT | Degenerate dimension |
| `customer_key` | INT | FK → dim_customer |
| `product_key` | INT | FK → dim_product |
| `order_date_key` | INT | FK → dim_date |
| `order_status` | TEXT | Denormalized from stg_orders |
| `country` | TEXT | Denormalized from stg_orders |
| `sales_channel` | TEXT | Denormalized from stg_orders |
| `shipping_method` | TEXT | Denormalized from stg_orders |
| `quantity` | INT | Measure |
| `unit_price` | NUMERIC(10,2) | Measure |
| `discount` | NUMERIC(10,4) | Measure |
| `line_total` | NUMERIC(12,2) | Measure — cleaned and recalculated from quantity × unit_price × (1 − discount) |
| `ghost_product_flag` | BOOLEAN | Exclude for clean revenue reporting |
| `zero_unit_price_flag` | BOOLEAN | Affects revenue totals |
| `line_total_mismatch_flag` | BOOLEAN | Raw line_total did not match recalculated value |

**Join path for customer_key:** `stg_order_items` does not carry `customer_id`. It is joined to `stg_orders` on `order_id` first, then `customer_id` is used to look up `dim_customer.customer_key`.

---

### 5.2 `fact_payments`

**Grain:** one row per payment transaction.

| Column | Type | Role |
|---|---|---|
| `fact_payment_key` | INT | Surrogate PK |
| `payment_id` | TEXT | Degenerate dimension |
| `order_id` | TEXT | Degenerate dimension |
| `customer_key` | INT | FK → dim_customer |
| `payment_key` | INT | FK → dim_payment |
| `payment_date_key` | INT | FK → dim_date |
| `order_status` | TEXT | Denormalized from stg_orders |
| `country` | TEXT | Denormalized from stg_orders |
| `sales_channel` | TEXT | Denormalized from stg_orders |
| `payment_amount` | NUMERIC(12,2) | Measure |
| `ghost_order_flag` | BOOLEAN | Payment references an order not in raw_orders |

**Join path for customer_key:** `stg_payments` carries `order_id` but not `customer_id`. The fact INSERT joins to `stg_orders` first to retrieve `customer_id`, then looks up `dim_customer.customer_key`.

**Filtering note:** Use `payment_status = 'Paid'` from `dim_payment` when calculating realized revenue. Rows with status 'Failed', 'Pending', or 'Refunded' represent uncommitted or reversed transactions.

---

### 5.3 `fact_returns`

**Grain:** one row per return event.

| Column | Type | Role |
|---|---|---|
| `fact_return_key` | INT | Surrogate PK |
| `return_id` | TEXT | Degenerate dimension |
| `order_id` | TEXT | Degenerate dimension |
| `customer_key` | INT | FK → dim_customer |
| `product_key` | INT | FK → dim_product |
| `return_reason_key` | INT | FK → dim_return_reason (nullable) |
| `return_date_key` | INT | FK → dim_date |
| `order_status` | TEXT | Denormalized from stg_orders |
| `country` | TEXT | Denormalized from stg_orders |
| `sales_channel` | TEXT | Denormalized from stg_orders |
| `refund_amount` | NUMERIC(12,2) | Measure — ABS-corrected value from staging |
| `ghost_product_flag` | BOOLEAN | Product ID is a ghost record |
| `ghost_order_flag` | BOOLEAN | Order ID not found in raw_orders |

**Join path for customer_key:** `stg_returns` carries `order_id` but not `customer_id`. The fact INSERT joins to `stg_orders` first.

**Join path for return_reason_key:** Text-based join on `stg_returns.return_reason = dim_return_reason.return_reason`. The join is guaranteed to succeed because both tables source from `stg_returns`.

**Validated integrity findings (EDA — 2026-06-23):**

| Check | Result |
|---|---|
| Duplicate `return_id` values | 0 — every row is a unique physical return event |
| Orders with both 'Returned' and 'Refunded' status | 0 — the two statuses represent distinct order lifecycles and never co-exist on the same order |
| Orders with more than one return row | 44 — all have exactly 2 rows, both carrying the same `order_status`; represents two separate products returned from the same order |
| Rows with `order_status = 'Unknown'` | 45 rows, €3,338 refund value (0.52% of total) — unmatched orders where `stg_orders` join found no record; included in refund aggregations but carry no order-level context |

**`order_status` note:** `fact_returns` carries one status value not present in `fact_order_items` — `'Unknown'` (45 rows). This reflects returns whose originating order could not be found in `stg_orders`. The value defaults to `'Unknown'` via the `COALESCE` in the fact INSERT. Because this slice is 0.52% of refund value, it does not materially affect aggregations but should be excluded from order-level breakdowns.

**`order_status` consistency in `fact_order_items`:** Separately confirmed that `order_status` is consistent within every `order_id` in `fact_order_items` (0 orders with mixed statuses). Status is an order-level attribute correctly denormalized onto the line-item fact.

**Net revenue calculation:** Use `refund_amount` from this table — not status-based line_total deductions — when computing net revenue. See `docs/BUSINESS_METADATA.md` §5 (Net Revenue — Method A vs Method B Decision Record) for full rationale and quantified discrepancy analysis.

---

### 5.4 `fact_marketing_touchpoints`

**Grain:** one row per customer-campaign-channel touchpoint.

| Column | Type | Role |
|---|---|---|
| `fact_touchpoint_key` | INT | Surrogate PK |
| `marketing_touchpoint_id` | TEXT | Degenerate dimension |
| `customer_key` | INT | FK → dim_customer |
| `campaign_key` | INT | FK → dim_marketing_campaigns |
| `campaign_date_key` | INT | FK → dim_date |
| `clicked` | SMALLINT | Measure — binary (0/1), sum to count clicks |
| `converted` | SMALLINT | Measure — binary (0/1), sum to count conversions |
| `ghost_customer_flag` | BOOLEAN | Customer ID not in customer master |
| `converted_without_click_flag` | BOOLEAN | Conversion recorded with no prior click — data quality issue |

**Campaign key join:** composite match on `campaign_name + channel` to `dim_marketing_campaigns`.

**Rate calculations:**
- Click-through rate: `SUM(converted) / NULLIF(SUM(clicked), 0)`
- Conversion rate: `SUM(converted) / NULLIF(COUNT(*), 0)`

---

## 6. Cross-Fact Relationships

The four fact tables connect through shared dimension keys, most importantly `customer_key` and `order_id`.

Example: customers who interacted with a campaign can be compared with their purchase behaviour:

```sql
-- Customers who converted on a campaign, with their total order revenue
SELECT
    dc.customer_id,
    SUM(foi.line_total) AS total_revenue
FROM mart.fact_marketing_touchpoints fmt
JOIN mart.dim_customer dc ON fmt.customer_key = dc.customer_key
JOIN mart.fact_order_items foi ON fmt.customer_key = foi.customer_key
WHERE fmt.converted = 1
  AND foi.ghost_product_flag = FALSE
GROUP BY dc.customer_id;
```

**Important:** Fact tables should not be joined directly without a business rule to prevent row duplication. For revenue attribution, a defined attribution model is needed, for example:

> Last-click attribution within a 7-day window: if a customer clicked a campaign and placed an order within the next 7 days, the revenue credit goes to the most recent clicked campaign before the order.

---

## 7. Main Business Questions

### Sales

- How much revenue do we generate over time?
- Which month, quarter, or year has the highest sales?
- Which sales channel performs best?
- Which countries generate the most revenue?
- How do returns affect net revenue?

### Customer

- Which countries have the most active customers?
- Do loyalty members spend more than non-loyalty members?
- What is the average order value by customer segment?

### Product

- Which categories generate the most revenue?
- Which products sell frequently but have low margin?
- Are there products with suspicious or zero unit prices?
- Which products have the highest return rate?

### Operations

- Which shipping method is most commonly used?
- Are returns concentrated in specific product categories?
- Which payment methods generate the most paid revenue?
- Which payment methods have the highest refund or failure rate?
- How much revenue is pending and not yet confirmed?

### Marketing

- Which campaigns generate the most clicks and conversions?
- Which channels perform best by conversion rate?
- Which campaigns are associated with the most revenue after attribution?

---

## 8. Summary of Key Modelling Decisions

| Topic | Decision |
|---|---|
| `dim_order` | Removed — order attributes denormalized onto fact tables instead of an outrigger join |
| `fact_order_items` grain | One row per order line item |
| `fact_marketing_touchpoints` grain | One row per customer-campaign-channel touchpoint |
| `dim_marketing_campaigns` grain | One row per `campaign_name + channel` combination |
| Original `campaign_id` | Renamed to `marketing_touchpoint_id` in staging |
| Payment split | `dim_payment` holds descriptors; `fact_payments` holds payment_amount |
| Return reason split | `dim_return_reason` holds reason categories; `fact_returns` holds refund_amount |
| Unknown fallback rows | `-1` key in dim_customer, dim_product, dim_payment, dim_marketing_campaigns |
| No unknown row in dim_return_reason | NULL reasons handled inline in staging; guaranteed join to dim |
| Ghost and quality-flagged rows | Kept in fact tables and flagged — not deleted |
| `age_group` reference year | Fixed at 2024 (dataset max year), not CURRENT_DATE — stable across rebuilds |
| `age_group` buckets | 8 buckets: Unknown, Under 18, 18-29, 30-39, 40-49, 50-59, 60-69, 70+ |
| `birth_year < 1900` | Bucketed as Unknown — catches 1800/1890 placeholder values from source data |
| `order_id` on fact tables | Degenerate dimension — enables cross-fact joins without dim_order |
| Duplicate customer identity (2026-07-03) | Added `duplicate_customer_flag` + `canonical_customer_key` to dim_customer — additive only, no rows merged or deleted |

---

## 9. Dimension Table Validation Results

### dim_marketing_campaigns

| Check | Result |
|---|---:|
| Total rows | 99 |
| Unknown fallback rows (`campaign_key = -1`) | 1 |
| Duplicate `campaign_name + channel` combinations | 0 |
| NULL values in required columns | 0 |
| Unique campaign-channel combinations from staging | 98 |

Validation confirms the table is at the correct grain with one row per `campaign_name + channel` plus one unknown fallback row.

### dim_customer

| Check | Result |
|---|---:|
| Total rows | 8,365 |
| Unknown fallback rows (`customer_key = -1`) | 1 |
| Duplicate `customer_id` values | 0 |
| Duplicate-identity customers (`duplicate_customer_flag = true`, 2026-07-03) | 148 |
| `canonical_customer_key` populated for all real customers | Yes |

### dim_product

| Check | Result |
|---|---:|
| Total rows | 1,091 |
| Unknown fallback rows (`product_key = -1`) | 1 |
| Duplicate `product_id` values | 0 |

### dim_date

| Check | Result |
|---|---:|
| Total rows | 1,467 |
| Gaps in calendar sequence | 0 |

### dim_payment

| Check | Result |
|---|---:|
| Total rows | 31,466 |
| Unknown fallback rows (`payment_key = -1`) | 1 |
| Duplicate `payment_id` values | 0 |

### dim_return_reason

| Check | Result |
|---|---:|
| Total rows | 9 |
| Duplicate `return_reason` values | 0 |