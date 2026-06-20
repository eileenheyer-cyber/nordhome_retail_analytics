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
| raw_order_items | 75,473 | 379 negative quantities, 241 zero unit prices, 299 discounts out of range, 452 ghost product references | High |
| raw_payments | 31,936 | 471 extra duplicate rows, 1,930 missing payment_method, 7 methods with ~18 spelling variants, 440 payments with no matching order | High |
| raw_returns | 6,097 | 1,835 ghost products (30.10%), 60 ghost orders, 22 negative refunds, 105 returns before order date | High |
| raw_marketing_campaigns | 12,000 | No critical issues found | Low |

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

**Row count:** 75,473

**Duplicate order_item_id:** 0 — no duplicates found ✓

**Missing values**

All columns complete — no missing values found in any column.

| Column | Missing count |
|---|---|
| order_item_id | 0 ✓ |
| order_id | 0 ✓ |
| product_id | 0 ✓ |
| quantity | 0 ✓ |
| unit_price | 0 ✓ |
| discount | 0 ✓ |
| line_total | 0 ✓ |

**Numeric field issues**

All numeric fields are valid formats — issues are with the values, not the format.

| Issue | Count | Notes |
|---|---|---|
| Non-numeric quantity | 0 ✓ | All values are valid numbers |
| Negative quantity | 379 | Business logic violation |
| Zero quantity | 0 ✓ | No zero quantities |
| Non-numeric unit_price | 0 ✓ | All values are valid numbers |
| Zero unit_price | 241 | Missing price — same treatment as list_price = 0 in products |
| Non-numeric discount | 0 ✓ | All values are valid numbers |
| Discount out of range (not 0–1) | 299 | Values outside valid 0%–100% range |

**Referential integrity**

| Issue | Count |
|---|---|
| Items with no matching order | 0 ✓ |
| Items with no matching product | 452 |

**Ghost product references**

All 452 items with no matching product follow the `PROD-GHOST-*` pattern — confirmed by check 4.6. There are no other types of missing product references in this table.

| Issue | Count | % of rows |
|---|---|---|
| Ghost product_id (PROD-GHOST-* pattern) | 452 | 0.60% |

---

## 5. raw_payments

**Row count:** 31,936

**Duplicate payment_id**

471 extra rows — rows above the one kept after deduplication. All visible duplicates show count of exactly 2, consistent with raw_orders pattern.

**Missing values**

| Column | Missing count | Notes |
|---|---|---|
| payment_id | 0 ✓ | Clean |
| order_id | 0 ✓ | Clean |
| payment_method | 1,930 | 6.05% of rows — largest missing value issue in this table |
| payment_status | 0 ✓ | Clean |
| payment_date | 0 ✓ | Clean |
| payment_amount | 0 ✓ | Clean |

**payment_method value distribution**

7 real payment methods represented by ~18 different spellings, casing, and format variants. 1,930 NULLs in addition.

| Canonical method | Raw variants | Approx. count |
|---|---|---|
| Credit Card | CC, Credit Card, creditcard, card | ~7,118 |
| Bank Transfer | BankTransfer, Bank Transfer, bank transfer | ~5,262 |
| Debit Card | debit, Debit Card, Debit | ~5,319 |
| PayPal | PAYPAL, paypal, PayPal | ~5,252 |
| Apple Pay | Apple Pay, applepay | ~3,495 |
| Buy Now Pay Later | Buy Now Pay Later | ~1,798 |
| Klarna | Klarna | ~1,762 |
| NULL | — | 1,930 |

**payment_date format variety**

3 formats present. All 31,936 rows accounted for — no unrecognised formats, no NULLs.

| Format | Row count |
|---|---|
| YYYY-MM-DD | 24,982 |
| MM-DD-YYYY | 3,489 |
| DD/MM/YYYY | 3,465 |

**Numeric field issues**

| Issue | Count |
|---|---|
| Non-numeric payment_amount | 0 ✓ |
| Negative payment_amount | 0 ✓ |

**Ghost order references**

| Issue | Count |
|---|---|
| order_id not found in raw_orders | 440 |

---

## 6. raw_returns

**Row count:** 6,097

**Duplicate return_id:** 0 — no duplicates found ✓

**Missing values**

| Column | Missing count | Notes |
|---|---|---|
| return_id | 0 | Clean ✓ |
| order_id | 0 | Clean ✓ |
| product_id | 0 | Clean ✓ |
| return_date | 0 | Clean ✓ |
| return_reason | 634 | 10.4% of rows — kept as NULL, mapped to 'Not Provided' in staging |
| refund_amount | 0 | Clean ✓ |

**return_reason value distribution**

| return_reason | Count |
|---|---|
| No longer needed | 711 |
| Not as described | 701 |
| Damaged on arrival | 692 |
| Better price elsewhere | 682 |
| Wrong item sent | 674 |
| Duplicate order | 673 |
| Poor quality | 668 |
| Changed mind | 662 |
| NULL | 634 |

8 clean reason values — no inconsistencies or casing variants found ✓

**return_date format variety**

| Format | Row count |
|---|---|
| YYYY-MM-DD | 4,821 |
| DD/MM/YYYY | 649 |
| MM-DD-YYYY | 627 |

All 6,097 rows accounted for — no unrecognised formats, no NULLs expected ✓

**Numeric field issues**

| Issue | Count |
|---|---|
| Non-numeric refund_amount | 0 ✓ |
| Negative refund_amount | 22 |

**Ghost references — most critical issue in this dataset**

| Issue | Count | % of rows | Severity |
|---|---|---|---|
| product_id not matching raw_products | 1,835 | 30.10% | High |
| order_id not matching raw_orders | 60 | 0.98% | Medium |

Ghost product IDs follow the `PROD-GHOST-*` pattern — intentional dirty records that cannot be corrected. Ghost order IDs are regular-looking IDs missing from the raw_orders master table.

**Returns before order date**

| Issue | Count |
|---|---|
| return_date before order_date | 105 |

---

## 7. raw_marketing_campaigns

**Row count:** 12,000

**Duplicate campaign_id:** 0 — no duplicates found ✓

**Missing values**

All columns complete — no missing values found in any column.

| Column | Missing count |
|---|---|
| campaign_id | 0 ✓ |
| customer_id | 0 ✓ |
| campaign_name | 0 ✓ |
| channel | 0 ✓ |
| campaign_date | 0 ✓ |
| clicked | 0 ✓ |
| converted | 0 ✓ |

**channel value distribution**

7 distinct channels, all clean values — no casing variants or spelling differences found ✓

| channel | Count |
|---|---|
| Display | 1,760 |
| Push Notification | 1,751 |
| Influencer | 1,736 |
| Affiliate | 1,713 |
| SMS | 1,691 |
| Paid Social | 1,680 |
| Email | 1,669 |

**campaign_date format variety**

| Format | Row count |
|---|---|
| YYYY-MM-DD | 9,390 |
| DD/MM/YYYY | 1,356 |
| MM-DD-YYYY | 1,254 |

All 12,000 rows accounted for — no unrecognised formats, no NULLs ✓

**clicked / converted value distribution**

| clicked | converted | Count | Notes |
|---|---|---|---|
| 0 | 0 | 8,381 | Not clicked, not converted |
| 1 | 0 | 2,886 | Clicked but not converted |
| 1 | 1 | 733 | Clicked and converted |

No row has converted=1 with clicked=0 — no attribution logic issue found ✓

**Ghost customer references**

| Issue | Count |
|---|---|
| touchpoints with no matching customer_id | 0 ✓ |

**No critical issues found** — cleanest table in the dataset. All flag checks confirm 0 issues.