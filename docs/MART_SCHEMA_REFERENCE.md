# NordHome — Mart Schema Reference (Quick Lookup)

> Personal cheat sheet for writing queries against `mart.*` without re-checking every time.
> Pulled live from the database. `DATA_DICTIONARY.md` covers the `raw` layer and known dirtiness — this file covers the analysis-ready `mart` layer only.
> For metric definitions (return rate, AOV, net revenue, etc.), see `business_rules/BUSINESS_METADATA.md`, not this file.

---

## Dimension Tables

### `mart.dim_customer` (PK: `customer_key`)

| Column | Type |
|---|---|
| `customer_key` | integer (PK) |
| `customer_id` | text |
| `full_name` | text |
| `email` | text |
| `phone` | text |
| `country` | text |
| `gender` | text |
| `birth_year` | integer |
| `age_group` | text |
| `registration_date` | date |
| `registration_year` | integer |
| `loyalty_member` | boolean |
| `missing_email_flag` | boolean |
| `missing_phone_flag` | boolean |
| `missing_registration_date_flag` | boolean |
| `is_unknown_customer` | boolean |
| `created_at` | timestamp |
| `duplicate_customer_flag` | boolean |
| `canonical_customer_key` | integer |

`customer_key = -1` = unmatched customer. Exclude from segmentation/CLV/retention, keep for overall revenue.

---

### `mart.dim_product` (PK: `product_key`)

| Column | Type |
|---|---|
| `product_key` | integer (PK) |
| `product_id` | text |
| `product_name` | text |
| `category` | text |
| `subcategory` | text |
| `brand` | text |
| `unit_cost` | numeric |
| `list_price` | numeric |
| `launch_date` | date |
| `discontinued_flag` | boolean |
| `price_issue_flag` | boolean |
| `product_quality_status` | text |
| `created_at` | timestamp |

`product_key = -1` = unmatched product. `list_price` is statistically independent from `unit_price` (fact table) — don't use it for realized-revenue margin.

---

### `mart.dim_date` (PK: `date_key`, format `YYYYMMDD` int)

| Column | Type |
|---|---|
| `date_key` | integer (PK) |
| `full_date` | date |
| `year` | integer |
| `quarter` | integer |
| `month_number` | integer |
| `month_name` | text |
| `year_month` | text |
| `day_of_month` | integer |
| `day_of_week_number` | integer (ISO: 1=Mon…7=Sun) |
| `day_of_week_name` | text |
| `is_weekend` | boolean |

Covers the full date range across orders, payments, returns, and campaigns. Use `dd.year` / `dd.year_month` directly — don't `EXTRACT()` from a `*_date_key` int, it isn't a date type.

---

### `mart.dim_order` (PK: `order_key`)

| Column | Type |
|---|---|
| `order_key` | integer (PK) |
| `order_id` | text |
| `order_date` | date |
| `order_year` | integer |
| `order_month` | integer |
| `order_quarter` | integer |
| `order_status` | text |
| `country` | text |
| `sales_channel` | text |
| `shipping_method` | text |

⚠️ **No `.sql` script for this table exists in `03_data_modeling/`** — every other mart table has a corresponding build script, this one doesn't. It was either built directly in the DB or the script is missing from the repo. Not currently version-controlled — worth tracking down before relying on it for anything you need to reproduce.

---

### `mart.dim_payment` (PK: `payment_key`)

| Column | Type |
|---|---|
| `payment_key` | integer (PK) |
| `payment_id` | text |
| `payment_method` | text |
| `payment_status` | text |
| `payment_date` | date |
| `created_at` | timestamp |

---

### `mart.dim_return_reason` (PK: `return_reason_key`)

| Column | Type |
|---|---|
| `return_reason_key` | integer (PK) |
| `return_reason` | text |
| `reason_category` | text |
| `created_at` | timestamp |

No unknown-fallback row needed — every reason is mapped inline (blank/NULL → `'Unknown'`).

---

### `mart.dim_marketing_campaigns` (PK: `campaign_key`)

| Column | Type |
|---|---|
| `campaign_key` | integer (PK) |
| `campaign_name` | text |
| `channel` | text |

---

## Fact Tables

### `mart.fact_order_items` — grain: **one row per order line item**

| Column | Type | Notes |
|---|---|---|
| `fact_order_item_key` | integer (PK) | |
| `order_item_id` | text | degenerate dimension |
| `order_id` | text | degenerate dimension |
| `customer_key` | integer | FK → `dim_customer` |
| `product_key` | integer | FK → `dim_product` |
| `order_date_key` | integer | FK → `dim_date` |
| `order_status` | text | denormalized from order |
| `country` | text | denormalized from order |
| `sales_channel` | text | denormalized from order |
| `shipping_method` | text | denormalized from order |
| `quantity` | integer | measure |
| `unit_price` | numeric | measure — realized price |
| `discount` | numeric | measure |
| `line_total` | numeric | measure |
| `ghost_product_flag` | boolean | exclude for clean revenue/margin |
| `zero_unit_price_flag` | boolean | |
| `line_total_mismatch_flag` | boolean | |
| `created_at` | timestamp | |

---

### `mart.fact_returns` — grain: **one row per return**

| Column | Type | Notes |
|---|---|---|
| `fact_return_key` | integer (PK) | |
| `return_id` | text | degenerate dimension |
| `order_id` | text | degenerate dimension |
| `customer_key` | integer | FK → `dim_customer` |
| `product_key` | integer | FK → `dim_product` |
| `return_reason_key` | integer | FK → `dim_return_reason` (nullable) |
| `return_date_key` | integer | FK → `dim_date` |
| `order_status` | text | denormalized — may not match `fact_order_items.order_status` for the same `order_id` |
| `country` | text | denormalized |
| `sales_channel` | text | denormalized |
| `refund_amount` | numeric | measure — use for Cash-Based Net Revenue |
| `ghost_product_flag` | boolean | ~30% of rows — exclude for product-level attribution, keep for company-wide totals |
| `ghost_order_flag` | boolean | |
| `created_at` | timestamp | |

⚠️ **No `quantity` column** — one row = one return event, not units returned. Item return rate must compare event-counts to event-counts (`COUNT(order_item_id)`), never `SUM(quantity)`.

---

### `mart.fact_payments` — grain: **one row per payment**

| Column | Type | Notes |
|---|---|---|
| `fact_payment_key` | integer (PK) | |
| `payment_id` | text | degenerate dimension |
| `order_id` | text | degenerate dimension |
| `customer_key` | integer | FK → `dim_customer` |
| `payment_key` | integer | FK → `dim_payment` |
| `payment_date_key` | integer | FK → `dim_date` |
| `order_status` | text | denormalized |
| `country` | text | denormalized |
| `sales_channel` | text | denormalized |
| `payment_amount` | numeric | measure |
| `ghost_order_flag` | boolean | |
| `created_at` | timestamp | |

Filter `dim_payment.payment_status = 'Paid'` before treating `payment_amount` as realized revenue.

---

### `mart.fact_marketing_touchpoints` — grain: **one row per customer-campaign-channel touchpoint**

| Column | Type | Notes |
|---|---|---|
| `fact_touchpoint_key` | integer (PK) | |
| `marketing_touchpoint_id` | text | degenerate dimension |
| `customer_key` | integer | FK → `dim_customer` |
| `campaign_key` | integer | FK → `dim_marketing_campaigns` |
| `campaign_date_key` | integer | FK → `dim_date` |
| `clicked` | smallint | 0/1 measure |
| `converted` | smallint | 0/1 measure |
| `ghost_customer_flag` | boolean | |
| `converted_without_click_flag` | boolean | |
| `created_at` | timestamp | |

CTR = `SUM(clicked)/COUNT(*)`. Conversion rate = `SUM(converted)/SUM(clicked)` or `SUM(converted)/COUNT(*)` depending on the question — label which one you're using.

---

*Last generated from live DB: 2026-07-09. If you add columns or new mart tables, re-check `information_schema.columns` and update this file — it's not auto-synced.*