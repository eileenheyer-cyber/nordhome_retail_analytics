

## customer table

**data quality issues**

| Issue                              | What you should do                                                | Why                                                                    |
| ---------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Leading/trailing spaces in text    | Trim customer names, emails, phone numbers, countries, and cities. | Extra spaces can create duplicate-looking values and poor joins.       |
| Name casing inconsistency          | Combine first and last name into `full_name` and standardize casing. | Clean names are easier to read in reports and customer analysis.       |
| Invalid or missing email values    | Validate email format, lowercase valid emails, and set invalid values to `NULL`. | Email quality affects customer communication and deduplication.        |
| Phone number spacing               | Remove internal whitespace from phone numbers.                    | Consistent phone formatting improves customer data quality.            |
| Country spelling variants          | Map variants such as `DE`, `Deutschland`, and `Germany` into one value. | Country variants can split customer counts across multiple categories. |
| Mixed `registration_date` formats  | Convert valid date formats into one `DATE` column.                | Registration dates are needed for customer growth and cohort analysis. |
| `birth_year` stored as text        | Convert valid four-digit values into `INTEGER`.                   | Birth year is needed for age and demographic analysis.                 |
| Inconsistent loyalty values        | Convert `Y/N`, `Yes/No`, `TRUE/FALSE`, and `1/0` into Boolean values. | Loyalty analysis requires one consistent true/false field.             |
| Duplicate customer records         | Keep one row per `customer_id`, preferring the latest registration date. | Duplicates can overcount customers and distort customer metrics.       |

**cleaning decisions**

| Column / Issue                     | Severity | Cleaning decision                                                                                                                     |
| ---------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `customer_id`                      | High     | Trim values and convert empty strings to `NULL`. Rows with missing `customer_id` are excluded during deduplication.                   |
| `first_name` and `last_name`       | Medium   | Trim values, standardize casing with `INITCAP()`, and combine them into `full_name`.                                                   |
| `email`                            | High     | Keep only emails matching a valid email pattern, lowercase valid emails, and set invalid or empty emails to `NULL`.                   |
| `phone`                            | Medium   | Trim phone values and remove whitespace using `REGEXP_REPLACE()`. Empty phone values become `NULL`.                                   |
| `country`                          | High     | Map known country variants to canonical names such as `Germany`, `Austria`, `Switzerland`, and `Netherlands`.                         |
| `city`                             | Low      | Trim and standardize casing with `INITCAP()` for reporting consistency.                                                               |
| `gender`                           | Low      | Trim values and convert empty strings to `NULL`.                                                                                      |
| `marketing_channel`                | Low      | Trim values and convert empty strings to `NULL`; source values are treated as mostly clean.                                           |
| `registration_date` stored as text | High     | Convert valid `YYYY-MM-DD`, `DD/MM/YYYY`, and `DD.MM.YYYY` values into a proper `DATE`. Invalid dates become `NULL`.                 |
| `birth_year` stored as text        | High     | Convert valid `YYYY` and `YYYY.0` values into `INTEGER`. Invalid or empty values become `NULL`.                                      |
| `loyalty_member` variants          | High     | Convert true-like values (`true`, `t`, `yes`, `y`, `1`) to `TRUE` and false-like values (`false`, `f`, `no`, `n`, `0`) to `FALSE`. |
| Duplicate `customer_id` values     | High     | Use `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY registration_date DESC NULLS LAST)` and keep `row_num = 1`.                |

**validation query**

Run this after creating `stg.stg_customers` to confirm which customer issues remain after cleaning.

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id_count,
    COUNT(*) FILTER (WHERE email IS NULL) AS missing_or_invalid_email_count,
    COUNT(*) FILTER (WHERE phone IS NULL) AS missing_phone_count,
    COUNT(*) FILTER (WHERE registration_date IS NULL) AS invalid_registration_date_count,
    COUNT(*) FILTER (WHERE birth_year IS NULL) AS missing_or_invalid_birth_year_count,
    COUNT(*) FILTER (WHERE loyalty_member IS NULL) AS invalid_loyalty_member_count
FROM stg.stg_customers;
```


## product table

**data quality issues**

| Issue                            | What you should do                                                                                          | Why                                                                   |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Missing category values          | Infer from `subcategory` if the mapping is clear. Otherwise keep as `NULL` in `stg` or `Unknown` in `mart`. | Do not delete products only because category is missing.              |
| Prices stored as text            | Convert `unit_cost` and `list_price` to `NUMERIC`. Invalid values become `NULL`.                            | Prices must be numeric for revenue, margin, and Power BI measures.    |
| Launch date stored as text       | Convert `launch_date` to `DATE`. Invalid dates become `NULL`.                                               | Dates must be real date fields for time analysis.                     |
| Discontinued flag stored as text | Convert `Y/N`, `Yes/No`, `1/0` into `TRUE/FALSE`.                                                           | This should be Boolean, not text.                                     |
| `list_price = 0` (6 products)    | Root cause is missing price, not a cost logic error. Set `list_price` to NULL and flag with `price_issue_flag = TRUE`. | Zero is not a valid selling price. NULL is safer than 0 in margin and price calculations. |
| `list_price < unit_cost`         | Covered by `price_issue_flag` after zero prices are set to NULL. No auto-correction.                               | Cannot determine which value is wrong without business input.         |

**cleaning decisions**

| Column / Issue                      | Severity | Cleaning decision                                                                                                                                              |
| ----------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Missing values in `category`        | Medium   | Fill missing `category` values from `subcategory` when the mapping is clear. If no reliable mapping is possible, keep the value as `NULL` and add `missing_category_flag`. |
| `unit_cost` stored as text          | High     | Convert `unit_cost` into `NUMERIC(10,2)`. Empty or invalid values are set to `NULL`.                                                                           |
| `list_price` stored as text         | High     | Convert `list_price` into `NUMERIC(10,2)`. Zero and invalid values are set to `NULL`.                                                                          |
| `list_price = 0` (6 products)       | High     | Set to `NULL` — zero is not a valid selling price. Flag with `price_issue_flag = TRUE` to document why the value is NULL.                                      |
| `list_price` lower than `unit_cost` | High     | Keep both values unchanged. Flag with `price_issue_flag = TRUE`. Do not auto-correct because it is unclear which value is wrong.                               |
| `launch_date` stored as text        | Low      | Convert `launch_date` into proper `DATE` format. All 1,090 rows use YYYY-MM-DD in raw data — no format issues found.                                          |
| `discontinued_flag` stored as text  | Low      | Convert `Y`/`N` to `TRUE`/`FALSE`. Raw data only contains Y and N — no inconsistencies found.                                                                  |
| `missing_category_flag`             | Medium   | Add flag when category is still NULL after subcategory inference. Affects products that could not be mapped to any category.                                    |

**impact on analysis**

Setting `list_price = NULL` for the 6 zero-price products affects the following:

| Analysis | Effect |
| --- | --- |
| Revenue (`order_items.unit_price * quantity`) | Not affected — revenue uses transaction price, not product list price |
| Margin (`list_price - unit_cost`) | Returns NULL for these 6 products — excluded from margin calculations automatically |
| Average list price by category | These 6 products excluded from AVG() — NULL is ignored by SQL aggregations |
| Price distribution / catalog analysis | 6 fewer products in any price range analysis |
| Power BI price measures | Will show BLANK for these products — correct behaviour |

Keeping `list_price = 0` would be worse: a zero selling price in margin calculations produces a misleading large negative margin. NULL correctly signals missing data and is handled gracefully by all SQL aggregations.


## orders table

**data quality issues**

| Issue | What you should do | Why |
|---|---|---|
| Duplicate order_ids (all appear exactly twice) | Deduplicate using `ROW_NUMBER()`, keep one row per `order_id`. Add `duplicate_order_id_flag` before deduplication so the issue is documented. | Duplicate orders would inflate order counts, AOV, and revenue. |
| `order_date` stored as text in 3 formats | Parse all 3 formats (`YYYY-MM-DD`, `DD/MM/YYYY`, `MM-DD-YYYY`) to `DATE`. Invalid dates become `NULL`. | Date is required for time-series, trend, and cohort analysis. |
| 496 orders with no matching customer_id | Keep orders, flag with `ghost_customer_flag = TRUE`. Map to `customer_key = -1` in the mart. | Orders still contain valid transaction data even without a matched customer. |
| Country spelling variants | Apply same country mapping as `stg_customers`. | Consistent country values are needed for geographic analysis. |
| Cancelled / Refunded / Returned order statuses | Do not remove these rows. Document in business rules that they should be excluded from revenue analysis. | Removing them silently would break return-rate and cancellation-rate analysis. |

**cleaning decisions**

| Column / Issue | Severity | Cleaning decision |
|---|---|---|
| Duplicate `order_id` values | High | Flag all rows where `order_id` appears more than once with `duplicate_order_id_flag = TRUE`. Deduplicate using `ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date ASC NULLS LAST)` and keep `row_num = 1`. |
| `order_date` stored as text | High | Parse `YYYY-MM-DD`, `DD/MM/YYYY`, and `MM-DD-YYYY` to `DATE`. Unrecognised formats become `NULL`. All 31,465 rows matched one of the 3 formats — no NULL dates expected. |
| Ghost customer references (496 rows) | Medium | Keep all orders. Add `ghost_customer_flag = TRUE` where `customer_id` does not exist in `raw_customers`. These orders will receive `customer_key = -1` in the mart. |
| `country` spelling variants | Medium | Apply same mapping as `stg_customers`: ISO code, local name, and English name all map to a single canonical English name. |
| `order_status` values | Low | No cleaning needed. 6 clean values found: `Completed`, `Shipped`, `Processing`, `Cancelled`, `Refunded`, `Returned`. |
| `sales_channel` values | Low | Trim and standardise. No missing values found. |
| `shipping_method` values | Low | Trim and standardise. No missing values found. |

**business rule — order status and revenue**

Not all order statuses represent completed sales. Downstream analysis must apply this filter:

| Status | Include in revenue? | Notes |
|---|---|---|
| Completed | Yes | Fulfilled sale |
| Shipped | Yes | In transit — treat as revenue |
| Processing | Yes | In progress — treat as revenue |
| Cancelled | No | Order was cancelled before fulfilment |
| Refunded | No | Payment was returned to customer |
| Returned | No | Product was returned — use return table instead |


## order_items table

**data quality issues**

| Issue                              | What you should do                                                                 | Why                                                                 |
| ---------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Numeric values stored as text      | Convert `quantity`, `unit_price`, `discount`, and `line_total` into numeric types. | These fields are needed for revenue, discount, and quantity analysis. |
| Negative quantity values           | Convert negative quantities to positive values using `ABS()`.                     | Negative quantities can create incorrect negative sales values.       |
| Extreme quantity values            | Keep the original quantity, but create a capped quantity for safer analysis.       | Very large quantities can inflate sales and distort product analysis. |
| Zero or invalid unit prices        | Convert invalid prices to `NULL` and flag zero unit prices.                       | Unit price is required for accurate revenue calculations.             |
| Discounts outside the valid range  | Cap discounts between `0` and `1`, and flag values outside this range.            | Discounts below 0% or above 100% are not valid for normal analysis.   |
| Incorrect line totals              | Recalculate line total from cleaned quantity, unit price, and discount.           | Raw `line_total` may not match the expected revenue formula.          |
| Ghost product references           | Keep the row, but create a `ghost_product_flag`.                                  | These rows may not join correctly to the product table.               |

**cleaning decisions**

| Column / Issue                       | Severity | Cleaning decision                                                                                                                                         |
| ------------------------------------ | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `order_item_id`, `order_id`, `product_id` | High     | Trim text values and convert empty strings to `NULL`. Keep IDs as text because they are business keys, not numeric measures.                              |
| `quantity` stored as text             | High     | Convert valid whole-number text into `INTEGER`. Invalid values are set to `NULL` and flagged with `invalid_quantity_flag`.                                |
| Negative `quantity` values            | High     | Create a cleaned `quantity` using `ABS(quantity_original)` and flag affected rows with `negative_quantity_flag`.                                          |
| Extreme `quantity` values             | High     | Create `quantity_capped` using `LEAST(ABS(quantity_original), 99)` and flag rows above 99 with `extreme_quantity_flag`. Keep the original value as well. |
| `unit_price` stored as text           | High     | Convert valid values into `NUMERIC(10,2)`. Invalid values are set to `NULL` and flagged with `invalid_unit_price_flag`.                                  |
| Zero `unit_price` values              | High     | Keep the row, but flag zero prices with `zero_unit_price_flag` because they can make revenue incorrect.                                                   |
| `discount` stored as text             | Medium   | Convert valid values into `NUMERIC(10,4)` to preserve discount precision for revenue calculations.                                                        |
| `discount` below 0 or above 1         | High     | Create a cleaned `discount` capped between `0` and `1`, and flag affected rows with `discount_range_issue_flag`.                                         |
| `line_total` stored as text           | High     | Convert valid values into `NUMERIC(12,2)`. Invalid values are set to `NULL`.                                                                              |
| Raw `line_total` does not match formula | High   | Create `line_total_clean` using `quantity_capped * unit_price * (1 - discount)` and flag mismatches with `line_total_mismatch_flag`.                      |
| `product_id` contains ghost values    | Medium   | Keep the row in staging, but flag it with `ghost_product_flag` so it can be reviewed before modeling.                                                     |

**validation results**

After creating `staging.stg_order_items`, the issue flags were counted to confirm which suspected data quality issues actually exist.

| Flag column                   | True count | Interpretation                                                                 |
| ----------------------------- | ---------- | ------------------------------------------------------------------------------ |
| `invalid_quantity_flag`       | 0          | No invalid quantity formats were found. No correction needed.                  |
| `negative_quantity_flag`      | 379        | Negative quantities exist and were cleaned using `ABS(quantity_original)`.     |
| `extreme_quantity_flag`       | 228        | Extreme quantities exist and were capped in `quantity_capped`.                 |
| `invalid_unit_price_flag`     | 0          | No invalid unit price formats were found. No correction needed.                |
| `zero_unit_price_flag`        | 241        | Zero unit prices exist and were kept with a flag for review.                   |
| `invalid_discount_flag`       | 0          | No invalid discount formats were found. No correction needed.                  |
| `discount_range_issue_flag`   | 299        | Discounts below 0 or above 1 exist and were capped into the valid range.       |
| `ghost_product_flag`          | 452        | Some order items reference product IDs that may not exist in the product table. |


## orders table

**data quality issues**

| Issue                         | What you should do                                                       | Why                                                                      |
| ----------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| Mixed `order_date` formats    | Convert all valid date formats into one `DATE` column.                  | Orders need a real date field for time-series and cohort analysis.       |
| Duplicate `order_id` values   | Keep one row per `order_id` and flag duplicate order IDs.               | Duplicate orders can duplicate revenue when joined to order items.       |
| Missing `customer_id` values  | Keep the row, but flag missing customer IDs.                            | Orders without customers cannot be connected to customer analysis.       |
| Ghost customer references     | Keep the row, but create a `ghost_customer_flag`.                       | These orders may not join correctly to the customer table.               |
| Invalid order status values   | Standardize expected statuses and flag values outside the valid domain. | Incorrect statuses can distort order funnel and fulfillment analysis.    |
| Text formatting inconsistency | Trim text fields and standardize readable text formatting.              | Consistent text values prevent duplicate categories in reporting.        |

**cleaning decisions**


| Column / Issue | Severity | Cleaning decision |
|---|---|---|
| `order_id` | High | Trim values and convert empty strings to `NULL`. Rows with missing `order_id` are excluded because the order cannot be reliably keyed. |
| Duplicate `order_id` values | High | Use `COUNT(*) OVER (PARTITION BY order_id)` to flag duplicates, then keep one row per order using `ROW_NUMBER()`. |
| `customer_id` | Low | Trim values and convert empty strings to `NULL`. |
| Ghost `customer_id` values | Medium | Keep the row in staging, but flag customer IDs containing `GHOST` with `ghost_customer_flag`. |
| `order_date` stored as text | High | Convert valid `YYYY-MM-DD`, `DD/MM/YYYY`, and `MM-DD-YYYY` values into a proper `DATE`. |
| `order_date` validation | High | Flag rows where `order_date` is missing or outside the expected period from `2021-01-01` to `2024-06-30`. 
| `order_status` | Medium | Standardize text formatting and validate against the expected status domain. 
| `country` | Low | Trim and standardize casing for reporting consistency. |
| `sales_channel` | Low | Trim and standardize casing because source values are already clean. |
| `shipping_method` | Low | Trim and standardize casing for reporting consistency.  |

**validation query**

Run this after creating `stg.stg_orders` to confirm which issues actually exist.

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE duplicate_order_id_flag = TRUE) AS duplicate_order_id_count,
    COUNT(*) FILTER (WHERE missing_customer_id_flag = TRUE) AS missing_customer_id_count,
    COUNT(*) FILTER (WHERE ghost_customer_flag = TRUE) AS ghost_customer_count,
    COUNT(*) FILTER (WHERE invalid_order_date_flag = TRUE) AS invalid_order_date_count,
    COUNT(*) FILTER (WHERE invalid_order_status_flag = TRUE) AS invalid_order_status_count
FROM stg.stg_orders;
```
**validation results**

After creating `stg.stg_orders`, the issue flags were counted to confirm which suspected data quality issues actually exist.

| Flag column                   | True count | Interpretation                                                              |
| ----------------------------- | ---------- | --------------------------------------------------------------------------- |
| `duplicate_order_id_flag`     | 465        | Duplicate order IDs exist and were handled by keeping one row per order.    |
| `missing_customer_id_flag`    | 0          | No missing customer IDs were found. No correction needed.                   |
| `ghost_customer_flag`         | 248        | Some orders reference customer IDs that may not exist in the customer table. |
| `invalid_order_date_flag`     | 0          | No invalid order date formats were found. No correction needed.             |
| `invalid_order_status_flag`   | 0          | No invalid order statuses were found. No correction needed.                 |


## marketing_campaigns table

**data quality issues**

| Issue                                  | What you should do                                                | Why                                                                    |
| -------------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Mixed `campaign_date` formats          | Convert all valid date formats into one `DATE` column.            | Campaign dates are needed for time-based marketing analysis.           |
| `clicked` and `converted` stored as text | Convert valid `0` and `1` values into integer flags.              | These fields are needed for click-through and conversion-rate analysis. |
| Duplicate campaign touchpoints         | Check whether the same campaign/customer/date appears more than once. | Duplicates can overcount campaign sends, clicks, and conversions.       |
| Missing or ghost customer references   | Flag rows that cannot be connected to a valid customer.           | Customer references are needed for campaign attribution and segmentation. |
| Conversion without click               | Flag rows where `converted = 1` but `clicked = 0`.                | This may indicate an attribution or tracking logic issue.              |

**cleaning decisions**

| Column / Issue                    | Severity | Cleaning decision                                                                                                               |
| --------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `campaign_id`                     | High     | Trim values and convert empty strings to `NULL`. Rows with missing `campaign_id` are excluded because the campaign cannot be keyed. |
| `customer_id`                     | High     | Trim values and convert empty strings to `NULL`. Missing customer IDs are flagged with `missing_customer_id_flag`.              |
| Ghost `customer_id` values        | Medium   | Keep the row in staging, but flag customer IDs containing `GHOST` with `ghost_customer_flag`.                                   |
| `campaign_name`                   | Low      | Trim and standardize casing for reporting consistency.                                                                          |
| `channel`                         | Low      | Trim and standardize casing for reporting consistency.                                                                          |
| `campaign_date` stored as text    | High     | Convert valid `YYYY-MM-DD`, `DD/MM/YYYY`, and `MM-DD-YYYY` values into a proper `DATE`. Invalid dates become `NULL`.           |
| Invalid `campaign_date` values    | High     | Flag rows where date conversion fails using `invalid_campaign_date_flag`.                                                       |
| `clicked` stored as text          | Medium   | Convert valid `0` and `1` values into `INTEGER`. Invalid values become `NULL` and are flagged with `invalid_clicked_flag`.      |
| `converted` stored as text        | Medium   | Convert valid `0` and `1` values into `INTEGER`. Invalid values become `NULL` and are flagged with `invalid_converted_flag`.    |
| Duplicate campaign touchpoints    | Medium   | Use `COUNT(*) OVER (PARTITION BY campaign_id, customer_id, campaign_date)` to check duplicates and keep one row per touchpoint. |
| `converted = 1` and `clicked = 0` | Medium   | Keep the row, but flag it with `converted_without_click_flag` for attribution review.                                           |

**validation results**

After creating `stg.stg_marketing_campaigns`, the issue flags were counted to confirm which suspected data quality issues actually exist.

| Flag column                     | True count | Interpretation                                                       |
| ------------------------------- | ---------- | -------------------------------------------------------------------- |
| `duplicate_touchpoint_flag`     | 0          | No duplicate campaign touchpoints were found. No correction needed.  |
| `missing_customer_id_flag`      | 0          | No missing customer IDs were found. No correction needed.            |
| `ghost_customer_flag`           | 0          | No ghost customer references were found. No correction needed.       |
| `invalid_campaign_date_flag`    | 0          | No invalid campaign date formats were found. No correction needed.   |
| `invalid_clicked_flag`          | 0          | No invalid clicked values were found. No correction needed.          |
| `invalid_converted_flag`        | 0          | No invalid converted values were found. No correction needed.        |
| `converted_without_click_flag`  | 0          | No conversions without clicks were found. No correction needed.      |


## payments table

**data quality issues**

| Issue                              | What you should do                                                   | Why                                                                  |
| ---------------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Duplicate `payment_id` values      | Keep one row per `payment_id` and flag duplicate payment IDs.        | Duplicate payments can overstate collected revenue.                  |
| Payment method spelling variants   | Standardize values such as `CC`, `creditcard`, and `card`.           | Consistent payment methods are needed for payment-method analysis.   |
| Missing payment methods            | Keep the row, but flag missing payment methods.                      | Missing methods reduce the quality of payment-channel reporting.     |
| Ghost order references             | Keep the row, but create a `ghost_order_flag`.                       | These payments may not join correctly to the orders table.           |
| Mixed `payment_date` formats       | Convert all valid date formats into one `DATE` column.               | Payment dates are needed for time-based payment analysis.            |
| Payments before order date         | Keep the row, but flag payments before the related order date.       | This may indicate a data issue or a valid business process.          |
| Payment amount stored as text      | Convert valid payment amounts into `NUMERIC`.                        | Payment amount is needed for revenue and payment analysis.           |

**cleaning decisions**

| Column / Issue                    | Severity | Cleaning decision                                                                                                              |
| --------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `payment_id`                      | High     | Trim values and convert empty strings to `NULL`. Rows with missing `payment_id` are excluded because the payment cannot be keyed. |
| Duplicate `payment_id` values     | High     | Use `COUNT(*) OVER (PARTITION BY payment_id)` to flag duplicates, then keep one row per payment using `ROW_NUMBER()`.          |
| `order_id`                        | High     | Trim values and convert empty strings to `NULL`. Missing order IDs are flagged with `missing_order_id_flag`.                   |
| Ghost `order_id` values           | Medium   | Keep the row in staging, but flag order IDs containing `GHOST` with `ghost_order_flag`.                                        |
| `payment_method` variants         | Medium   | Standardize common variants into consistent values such as `Credit Card`, `PayPal`, `Apple Pay`, and `Klarna / BNPL`.          |
| Missing `payment_method` values   | Medium   | Keep the row, but flag missing methods with `missing_payment_method_flag`.                                                     |
| Invalid `payment_method` values   | Medium   | Flag non-null method values outside the accepted list using `invalid_payment_method_flag`.                                     |
| `payment_status`                  | Medium   | Standardize expected statuses and flag unexpected non-null values with `invalid_payment_status_flag`.                          |
| `payment_date` stored as text     | High     | Convert valid `YYYY-MM-DD`, `DD/MM/YYYY`, and `MM-DD-YYYY` values into a proper `DATE`. Invalid dates become `NULL`.          |
| `payment_amount` stored as text   | High     | Convert valid values into `NUMERIC(12,2)`. Invalid values become `NULL` and are flagged with `invalid_payment_amount_flag`.    |
| Negative `payment_amount` values  | High     | Keep the row, but flag negative amounts with `negative_payment_amount_flag`.                                                   |
| Payment before order date         | Medium   | Compare `payment_date` to `stg.stg_orders.order_date` and flag earlier payments with `payment_before_order_flag`.              |

**validation results**

After creating `stg.stg_payments`, the issue flags were counted to confirm which suspected data quality issues actually exist.

| Flag column                         | True count | Interpretation                                                            |
| ----------------------------------- | ---------- | ------------------------------------------------------------------------- |
| `duplicate_payment_id_flag`         | 471        | Duplicate payment IDs exist and were handled by keeping one row per payment. |
| `missing_order_id_flag`             | 0          | No missing order IDs were found. No correction needed.                    |
| `ghost_order_flag`                  | 220        | Some payments reference order IDs that may not exist in the orders table. |
| `missing_payment_method_flag`       | 1901       | Missing payment methods exist and were kept with a flag for review.       |
| `invalid_payment_method_flag`       | 0          | No invalid non-null payment method values were found. No correction needed. |
| `invalid_payment_status_flag`       | 0          | No invalid payment statuses were found. No correction needed.             |
| `invalid_payment_date_flag`         | 0          | No invalid payment date formats were found. No correction needed.         |
| `invalid_payment_amount_flag`       | 0          | No invalid payment amounts were found. No correction needed.              |
| `negative_payment_amount_flag`      | 0          | No negative payment amounts were found. No correction needed.             |
| `payment_before_order_flag`         | 0          | No payments before order date were found. No correction needed.           |


## returns table

**data quality issues**

| Issue                            | What you should do                                                     | Why                                                                  |
| -------------------------------- | ---------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Mixed `return_date` formats      | Convert all valid date formats into one `DATE` column.                 | Return dates are needed for return-rate and time-based analysis.     |
| Missing return reasons           | Fill missing reasons with `Not Provided` and keep a flag.              | Missing reasons reduce the quality of return-reason analysis.        |
| Negative refund amounts          | Convert refund amounts to positive values using `ABS()`.               | Negative refunds can distort refund and return-value calculations.   |
| Ghost order references           | Keep the row, but create a `ghost_order_flag`.                         | These returns may not join correctly to the orders table.            |
| Ghost product references         | Keep the row, but create a `ghost_product_flag`.                       | These returns may not join correctly to the product table.           |
| Unmatched order or product IDs   | Flag returns that do not match staging order or product records.       | Unmatched references can break return analysis by order or product.  |
| Returns before order date        | Keep the row, but flag returns before the related order date.           | This is a business-rule issue that may require review.               |

**cleaning decisions**

| Column / Issue                   | Severity | Cleaning decision                                                                                                              |
| -------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `return_id`                      | High     | Trim values and convert empty strings to `NULL`. Rows with missing `return_id` are excluded because the return cannot be keyed. |
| Duplicate `return_id` values     | High     | Use `COUNT(*) OVER (PARTITION BY return_id)` to flag duplicates, then keep one row per return using `ROW_NUMBER()`.            |
| `order_id`                       | High     | Trim values and convert empty strings to `NULL`. Missing order IDs are flagged with `missing_order_id_flag`.                   |
| `product_id`                     | High     | Trim values and convert empty strings to `NULL`. Missing product IDs are flagged with `missing_product_id_flag`.               |
| Ghost `order_id` values          | Medium   | Keep the row in staging, but flag order IDs containing `GHOST` with `ghost_order_flag`.                                        |
| Ghost `product_id` values        | Medium   | Keep the row in staging, but flag product IDs containing `GHOST` with `ghost_product_flag`.                                    |
| Unmatched `order_id` values      | High     | Join to `stg.stg_orders` and flag records with no matching order using `unmatched_order_flag`.                                 |
| Unmatched `product_id` values    | High     | Join to `stg.stg_products` and flag records with no matching product using `unmatched_product_flag`.                           |
| `return_date` stored as text     | High     | Convert valid `YYYY-MM-DD`, `DD/MM/YYYY`, and `MM-DD-YYYY` values into a proper `DATE`. Invalid dates become `NULL`.          |
| Missing `return_reason` values   | Medium   | Replace missing values with `Not Provided` and flag affected rows with `missing_return_reason_flag`.                           |
| `refund_amount` stored as text   | High     | Convert valid values into `NUMERIC(12,2)`. Invalid values become `NULL` and are flagged with `invalid_refund_amount_flag`.     |
| Negative `refund_amount` values  | High     | Create cleaned `refund_amount` using `ABS(refund_amount_original)` and flag affected rows with `negative_refund_amount_flag`. |
| Return before order date         | Medium   | Compare `return_date` to `stg.stg_orders.order_date` and flag earlier returns with `return_before_order_flag`.                 |

**validation results**

After creating `stg.stg_returns`, the issue flags were counted to confirm which suspected data quality issues actually exist.

| Flag column                     | True count | Interpretation                                                                 |
| ------------------------------- | ---------- | ------------------------------------------------------------------------------ |
| `duplicate_return_id_flag`      | 0          | No duplicate return IDs were found. No correction needed.                      |
| `missing_order_id_flag`         | 0          | No missing order IDs were found. No correction needed.                         |
| `missing_product_id_flag`       | 0          | No missing product IDs were found. No correction needed.                       |
| `ghost_order_flag`              | 60         | Some returns reference order IDs that may not exist in the orders table.       |
| `ghost_product_flag`            | 1835       | Some returns reference product IDs that may not exist in the product table.    |
| `unmatched_order_flag`          | 60         | Some returns could not be matched to `stg.stg_orders`.                         |
| `unmatched_product_flag`        | 1835       | Some returns could not be matched to `stg.stg_products`.                       |
| `invalid_return_date_flag`      | 0          | No invalid return date formats were found. No correction needed.               |
| `missing_return_reason_flag`    | 634        | Missing return reasons exist and were filled with `Not Provided`.              |
| `invalid_refund_amount_flag`    | 0          | No invalid refund amounts were found. No correction needed.                    |
| `negative_refund_amount_flag`   | 22         | Negative refund amounts exist and were cleaned using `ABS(refund_amount_original)`. |
| `return_before_order_flag`      | 105        | Some returns occur before the order date and were flagged for business review. |
