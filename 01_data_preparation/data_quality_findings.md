## Data Quality Findings — Raw Layer

Results from running `data_quality_checks.sql` against all 7 raw tables before any cleaning.

> For cleaning decisions made based on these findings, see `02_data_cleaning_transformation/data_cleaning_decisions.md`.

---

## Summary

| Table | Rows | Critical issues | Severity |
|---|---|---|---|
| raw_customers | 8,364 | Invalid emails, mixed date formats, inconsistent loyalty values | High |
| raw_products | — | Missing categories, text prices, text dates | High |
| raw_orders | 31,465 | Duplicate order_ids (all appear exactly twice), 496 ghost customer references | High |
| raw_order_items | — | 379 negative quantities, 452 ghost products, 241 zero prices | High |
| raw_payments | — | 471 duplicate payment IDs, 1,901 missing payment methods | High |
| raw_returns | — | 1,835 ghost products (30.10%), 105 returns before order date | High |
| raw_marketing_campaigns | — | No critical issues found | Low |

> `—` = run check to get exact count

---

## 1. raw_customers

**Row count:** 8,364

**Duplicate customer_id:** 0 — no duplicates found ✓

**Missing values**

| Column | Missing count | Notes |
|---|---|---|
| customer_id | 0 | Clean ✓ |
| first_name | 0 | Clean ✓ |
| last_name | 0 | Clean ✓ |
| email | 406 | — |
| phone | 1,013 | — |
| country | 0 | Clean ✓ |
| city | 0 | Clean ✓ |
| registration_date | 0 | Clean ✓ |
| birth_year | 670 | — |
| gender | 0 | Clean ✓ |
| loyalty_member | 0 | Clean ✓ |

**Email quality**

| Category | Count |
|---|---|
| Valid email format | 6,607 |
| Invalid email format | 1,351 |
| Missing email | 406 |

**registration_date format variety**

| Format | Row count |
|---|---|
| YYYY-MM-DD | 6,554 |
| DD/MM/YYYY | 927 |
| MM-DD-YYYY | 883 |
| Missing | 0 |

**loyalty_member value distribution**

8 distinct raw values found for a single boolean concept — no NULLs (confirmed in check 1.3).

| Raw value | Count | Meaning |
|---|---|---|
| Yes | 1,085 | TRUE |
| FALSE | 1,056 | FALSE |
| No | 1,050 | FALSE |
| Y | 1,048 | TRUE |
| 0 | 1,047 | FALSE |
| N | 1,040 | FALSE |
| TRUE | 1,036 | TRUE |
| 1 | 1,002 | TRUE |

**birth_year anomalies**

Two issues found:

1. **Float suffix** — all 7,694 non-null rows stored as `YYYY.0` (e.g. `1990.0`) — CSV float export issue affecting every value.

2. **Impossible birth years** — 71 rows have values that cannot belong to real customers:

| Value | Count | Problem |
|---|---|---|
| 1800.0 | 23 | 224 years old |
| 1890.0 | 21 | 134 years old |
| 2020.0 | 18 | 4 years old at dataset start (2021) |
| 2025.0 | 9 | Future birth year |

These 71 rows should be set to NULL in staging, not cast to integer.

**Country value distribution**

Each country name appears in multiple formats — ISO code, local language name, English name, mixed casing.
10 markets confirmed in data: Germany, Austria, Switzerland, Netherlands, France, Belgium, Sweden, Denmark, Norway, Poland.

> Note: Poland appears in raw data — not Finland as originally expected. Verify against `BUSINESS_METADATA.md`.

Partial distribution (top variants visible — run check 1.7 for full list):

| Raw value | Count | Maps to |
|---|---|---|
| NO | 302 | Norway |
| Denmark | 284 | Denmark |
| Norway | 281 | Norway |
| AT | 279 | Austria |
| DK | 276 | Denmark |
| BE | 270 | Belgium |
| denmark | 265 | Denmark |
| Belgium | 263 | Belgium |
| PL | 262 | Poland |
| poland | 261 | Poland |
| SE | 258 | Sweden |
| sweden | 257 | Sweden |
| Poland | 257 | Poland |
| belgium | 252 | Belgium |
| Sweden | 251 | Sweden |
| norway | 250 | Norway |
| Austria | 245 | Austria |
| Schweiz | 240 | Switzerland |
| austria | 224 | Austria |
| The Netherlands | 218 | Netherlands |
| FR | 215 | France |
| france | 207 | France |
| Switzerland | 200 | Switzerland |
| Netherlands | 199 | Netherlands |
| NL | 196 | Netherlands |
| France | 194 | France |
| FRANCE | 194 | France |
| CH | 194 | Switzerland |
| netherlands | 187 | Netherlands |
| switzerland | 184 | Switzerland |
| DE | 168 | Germany |

---

## 2. raw_products

**Row count:** 1,090

**Duplicate product_id:** 0 — no duplicates found ✓

**Missing values**

| Column | Missing count | Notes |
|---|---|---|
| product_id | 0 | Clean ✓ |
| product_name | 0 | Clean ✓ |
| category | 36 | 3.3% missing — inferred from subcategory in staging |
| subcategory | 0 | Clean ✓ |
| brand | 0 | Clean ✓ |
| unit_cost | 0 | Clean ✓ |
| list_price | 0 | Clean ✓ |
| launch_date | 0 | Clean ✓ |
| discontinued_flag | 0 | Clean ✓ |

**Numeric fields stored as TEXT**

| Check | Count |
|---|---|
| Non-numeric list_price | 0 ✓ |
| Non-numeric unit_cost | 0 ✓ |

All price values are valid numbers — no format issues.

**Price logic issue — zero list_price**

| Issue | Count |
|---|---|
| list_price = 0.0 | 6 |

Root cause: all 6 products have `list_price = 0.0`, not a genuine cost-above-price scenario. The unit_cost values are valid (€15–€70) — the selling price is simply missing.

| product_id | product_name | category | unit_cost | list_price |
|---|---|---|---|---|
| PROD-0688 | Hair Oil Limited Edition | Beauty | 70.13 | 0.0 |
| PROD-0067 | Cable Organiser Limited Edition | Lifestyle | 68.49 | 0.0 |
| PROD-0664 | Milk Frother | Kitchen | 66.48 | 0.0 |
| PROD-0311 | Shea Butter Cream Classic | Beauty | 62.05 | 0.0 |
| PROD-0429 | Sticky Notes XL | Lifestyle | 51.63 | 0.0 |
| PROD-0559 | Wok Organic | Kitchen | 15.78 | 0.0 |

These 6 products will have `list_price` set to NULL in staging (zero price = missing data, same as invalid emails or unparseable dates) and `price_issue_flag = TRUE` to document why.

**launch_date format variety**

| Format | Row count |
|---|---|
| YYYY-MM-DD | 1,090 |

Only one format — no multi-format parsing needed. Cleaner than all other date columns.

**discontinued_flag value distribution**

| Value | Count |
|---|---|
| N | 991 |
| Y | 99 |

Only two values, no inconsistencies ✓

**category distribution**

5 categories exist. NULL = 36 (3.3%). Same category names appear multiple times with small counts — indicates invisible whitespace or casing differences in raw values (e.g. `"Home"` vs `"Home "`). Will consolidate correctly after `TRIM` + `INITCAP` in staging.

| Category | Clean count |
|---|---|
| Kitchen | 208 |
| Gifts | 207 |
| Lifestyle | 200 |
| Home | 197 |
| Beauty | 189 |
| NULL | 36 |
| Whitespace/casing variants | 53 |

**Ghost product IDs**

Some product IDs follow the pattern `PROD-GHOST-*` — intentional dirty records in the dataset.
These affect 30.10% of returns and 0.60% of order items.

---

## 3. raw_orders

**Row count:** 31,465

**Missing values**

All columns complete — no missing values found in any column.

| Column | Missing count |
|---|---|
| order_id | 0 ✓ |
| customer_id | 0 ✓ |
| order_date | 0 ✓ |
| order_status | 0 ✓ |
| country | 0 ✓ |
| sales_channel | 0 ✓ |
| shipping_method | 0 ✓ |

**Duplicate order_id**

Multiple order_ids appear more than once. All visible duplicates show a count of exactly 2 — no order_id appears 3 or more times.

| Issue | Notes |
|---|---|
| All duplicate order_ids appear exactly twice | No order appears 3+ times |

**order_date format variety**

Three formats present. All 31,465 rows accounted for — no unrecognised formats, no NULLs.

| Format | Row count |
|---|---|
| YYYY-MM-DD | 24,556 |
| DD/MM/YYYY | 3,459 |
| MM-DD-YYYY | 3,450 |

**order_status value distribution**

6 distinct values, all clean Pascal case — no inconsistencies or unexpected values.

| order_status | Count |
|---|---|
| Completed | 17,336 |
| Shipped | 6,363 |
| Processing | 2,426 |
| Cancelled | 2,194 |
| Refunded | 1,612 |
| Returned | 1,534 |

**Ghost customer references**

| Issue | Count |
|---|---|
| customer_id not found in raw_customers | 496 |

---

## 4. raw_order_items

**Row count:** run check 4.1

**Missing values:** run check 4.3

**Numeric field issues**

| Issue | Count |
|---|---|
| Negative quantity | 379 |
| Extreme quantity (> 99) | 228 |
| Zero unit_price | 241 |
| Discount out of range (not 0–1) | 299 |
| Invalid quantity format | 0 ✓ |
| Invalid unit_price format | 0 ✓ |
| Invalid discount format | 0 ✓ |

**Ghost product references**

| Issue | Count | % of rows |
|---|---|---|
| product_id not found in raw_products | 452 | 0.60% |

**Referential integrity — order_items with no matching order:** run check 4.5

---

## 5. raw_payments

**Row count:** run check 5.1

**Missing values**

| Column | Missing count |
|---|---|
| payment_id | run check 5.3 |
| order_id | run check 5.3 |
| payment_method | 1,901 |
| payment_status | run check 5.3 |
| payment_date | run check 5.3 |
| payment_amount | run check 5.3 |

**Duplicate payment_id**

| Issue | Count |
|---|---|
| Duplicate payment IDs | 471 |

**Ghost order references**

| Issue | Count |
|---|---|
| order_id not matching raw_orders | 220 |

**payment_method value distribution**

Multiple spellings found for the same method (e.g. `CC`, `creditcard`, `card`).
Exact distribution: run check 5.4.

**payment_date format variety:** run check 5.5

**Numeric field issues**

| Issue | Count |
|---|---|
| Non-numeric payment_amount | 0 ✓ |
| Negative payment_amount | 0 ✓ |

---

## 6. raw_returns

**Row count:** run check 6.1

**Missing values**

| Column | Missing count |
|---|---|
| return_id | run check 6.3 |
| order_id | run check 6.3 |
| product_id | run check 6.3 |
| return_date | run check 6.3 |
| return_reason | 634 |
| refund_amount | run check 6.3 |

**Ghost references — most critical issue in this dataset**

| Issue | Count | % of rows | Severity |
|---|---|---|---|
| product_id not matching raw_products | 1,835 | 30.10% | High |
| order_id not matching raw_orders | 60 | — | Medium |

Investigation note: Ghost product IDs follow `PROD-GHOST-*` pattern. Attempted reformatting to `PROD-117` and `PROD-000117` — neither matched existing product IDs. These are intentional dirty records.

**Negative refund amounts**

| Issue | Count |
|---|---|
| Negative refund_amount | 22 |

**Returns before order date**

| Issue | Count |
|---|---|
| return_date before order_date | 105 |

**return_date format variety:** run check 6.5

---

## 7. raw_marketing_campaigns

**Row count:** run check 7.1

**Missing values:** run check 7.3

**No critical issues found**

All staging validation flag checks returned 0:
- No duplicate touchpoints
- No ghost customer references
- No invalid date formats
- No invalid clicked / converted values
- No conversions without clicks

**channel value distribution:** run check 7.4

**clicked / converted value distribution:** run check 7.6