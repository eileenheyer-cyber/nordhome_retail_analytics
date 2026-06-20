# 1. Overview

This document summarizes the main data quality issues found in the raw tables before cleaning.  The raw tables was imported from CSV, therefore all columns are stored as `text`.  
This is acceptable in the raw layer because the raw table should preserve the original source structure.
The raw tables remain unchanged. Cleaning is applied in separate cleaned or mart tables.

List of raw tables:
- customers
- orders
- order_items
- products
- stores
- payments

# 2. Quality checks performed

The following checks were performed across the raw tables:

## **Missing or Nullable Key Values**

## **Duplicate Key Values**

## **Invalid Foreign Key Relationships**

## **Numeric Value Format and Range Issues**

## **Date Format and Date Validity Issue**

## **Inconsistent Category Value Issue**

## **Boolean Value Inconsistency**

## **Whitespace and Text Formatting Issue**

 **Summary of Main Data Quality Issues**

This section gives a short overview of the main data quality issues found in the raw data.  
The detailed checks, business impact, severity, and cleaning decisions are documented in the following sections.

| Data quality aspect | General meaning | Why it matters |
|---|---|---|
| *Missing or nullable key values* | Important identifier columns may be empty or missing. | This can break joins and make records difficult to connect across tables. |
| *Duplicate key values* | A key value appears more than once where it should be unique. | This can duplicate records after joins and lead to wrong counts or revenue values. |
| *Invalid foreign key relationships* | A record refers to another table, but the related parent record does not exist. | This can create unmatched records and broken relationships in the data model. |
| *Email format and validity issues* | Email values may be missing, invalid, or not usable for communication. | This affects customer communication, marketing analysis, and customer data quality. |
| *Country value inconsistency* | The same country appears in different formats, languages, or codes. | This can split one real country into several groups and lead to wrong country-level reporting. |
| *Date format and date validity issues* | Date values may be stored as text, use mixed formats, or contain invalid values. | This can affect time-based analysis, filtering, date relationships, and Power BI modelling. |
| *Numeric value format and range issues* | Numeric values may be stored as text, invalid, negative, or outside realistic business ranges. | This can directly affect revenue, quantity, price, discount, and payment calculations. |
| *Boolean value inconsistency* | Boolean values are stored in different formats, such as `Y`, `N`, `TRUE`, `FALSE`, `1`, or `0`. | This can lead to wrong filtering, grouping, and customer segmentation. |
| *Inconsistent category values* | Category values may contain spelling differences, casing differences, or different labels for the same meaning. | This can create incorrect grouping and messy report filters. |
| *Whitespace and text formatting issues* | Text values may contain leading spaces, trailing spaces, empty strings, or inconsistent casing. | This can create duplicate-looking values and incorrect grouping results. |

Overall, these issues do not mean that the raw data is unusable.  
They show which fields need to be cleaned, standardized, or validated before the data can be used for analysis and Power BI reporting.

# 3.Data Quality Issues and Cleaning decision

## Severity definition

- **High**: Issue can break analysis, joins, filtering, or business logic.
- **Medium**: Issue can lead to wrong grouping, segmentation, or reporting.
- **Low**: Issue is mostly formatting-related and easy to clean.

## 3.1 **Missing or Nullable Key Values**

**Check purpose**

Key columns were checked to identify missing or empty identifier values.

This check is important because key columns are needed to uniquely identify records and build relationships between tables.

**Result summary**

The check showed that some key columns are stored as nullable fields in the raw layer.

This is acceptable in the raw layer because the raw tables preserve the original source structure. However, key columns should not contain missing values in the cleaned tables.

Examples of important key columns:

| Table | Key column |
|---|---|
| customers | `customer_id` |
| orders | `order_id` |
| order_items | `order_item_id` |
| products | `product_id` |
| stores | `store_id` |
| payments | `payment_id` |

**Data quality issue**

Key columns may contain missing or empty values.

This can break joins between tables and make it difficult to build a reliable data model.

For example, if an order record has a missing `customer_id`, the order cannot be connected to the correct customer.

**Business impact**

This issue can affect customer analysis, order analysis, revenue reporting, and Power BI modelling.

Missing key values can lead to incomplete relationships, unmatched records, and wrong analysis results.

**Severity: High**

Missing key values can break joins, relationships, and business logic.

**Cleaning decision**

The original key columns will not be changed in the raw tables.

In the cleaned tables, key columns should be required and checked for non-null values.

Records with missing key values should be reviewed separately before they are used in analysis.

**Cleaning logic**

The cleaning should:

1. remove leading and trailing spaces from key values
2. convert empty strings to `NULL`
3. check whether key values are missing
4. keep valid key values
5. flag records with missing key values for review



## 3.2 **Duplicate Key Value Issue**

**Check purpose**

Key columns were checked to identify duplicate key values.

This check is important because primary key columns should uniquely identify each record in a table.

**Result summary**

The check was used to confirm whether key values appear more than once in tables where each key should be unique.

Examples:

| Table | Key column |
|---|---|
| customers | `customer_id` |
| orders | `order_id` |
| products | `product_id` |
| stores | `store_id` |
| payments | `payment_id` |

**Data quality issue**

Duplicate key values can create unreliable table relationships.

If a key value appears more than once in a table where it should be unique, joins can create duplicated records.

For example, if the same `product_id` appears multiple times in the product table, joining products to order items may duplicate sales rows and inflate revenue.

**Business impact**

This issue can affect reporting accuracy.

Duplicate key values can lead to wrong customer counts, wrong product counts, duplicated sales records, and incorrect revenue calculations.

**Severity: High**

Duplicate key values can directly affect joins, aggregation, and business reporting.

**Cleaning decision**

The original records will not be deleted automatically from the raw tables.

Duplicate key values should be reviewed before creating cleaned tables.

In the cleaned tables, each primary key should appear only once.

**Cleaning logic**

The cleaning should:

1. trim key values
2. check for duplicate key values
3. identify which records are duplicated
4. decide which record should be kept
5. exclude or flag duplicate records that cannot be safely resolved



## 3.3 **Invalid Foreign Key Relationship Issue**

**Check purpose**

Foreign key columns were checked to identify records that cannot be matched to their related parent table.

This check is important because the data model depends on correct relationships between tables.

**Result summary**

The check was used to confirm whether foreign key values in transaction tables exist in the related master tables.

Examples:

| Table | Foreign key | Related table |
|---|---|---|
| orders | `customer_id` | customers |
| orders | `store_id` | stores |
| order_items | `order_id` | orders |
| order_items | `product_id` | products |
| payments | `order_id` | orders |

**Data quality issue**

Some foreign key values may not have a matching record in the related parent table.

This means that some records cannot be correctly connected in the data model.

For example, if an `order_item` contains an `order_id` that does not exist in the orders table, the order item cannot be linked to a valid order.

**Business impact**

This issue can affect analysis and Power BI modelling.

Unmatched records can lead to missing sales details, incomplete customer order history, wrong product analysis, and broken relationships in the data model.

**Severity: High**

Invalid foreign key relationships can break joins and lead to incomplete or incorrect reporting.

**Cleaning decision**

The raw tables will not be changed.

Unmatched records should be identified and flagged during the cleaning process.

If the related parent record is missing, the affected record should not be used directly in the final analytical model without review.

**Cleaning logic**

The cleaning should:

1. trim key values
2. check whether foreign key values exist in the related parent table
3. identify unmatched records
4. flag unmatched records for review
5. exclude unresolved records from final analytical tables if necessary



## 3.4 **Numeric Value Format and Range Issue**

**Check purpose**

Numeric columns were checked to identify values stored as text, invalid numeric values, negative values, zero values, and unrealistic numeric ranges.

This check is important because numeric columns are used for calculations such as revenue, quantity, discounts, prices, and payment amounts.

**Result summary**

The check was used to confirm whether numeric fields can be safely converted into proper numeric data types.

Examples of important numeric columns:

| Table | Numeric column |
|---|---|
| order_items | `quantity` |
| order_items | `unit_price` |
| order_items | `discount_amount` |
| products | `price` |
| payments | `payment_amount` |

**Data quality issue**

Some numeric columns may be stored as text or may contain invalid numeric values.

Some values may also be outside the expected business range, such as negative quantities, negative prices, or unrealistic payment amounts.

**Business impact**

This issue can directly affect financial and sales analysis.

If numeric values are not cleaned correctly, revenue, average order value, product performance, discount analysis, and payment reporting may be wrong.

**Severity: High**

Numeric value issues can directly affect business calculations and reporting accuracy.

**Cleaning decision**

The original numeric columns will not be changed in the raw tables.

Cleaned numeric columns will be created in the cleaned tables.

Valid values will be converted into proper numeric data types.

Invalid, missing, or unrealistic values will be set to `NULL` or flagged for review, depending on the business rule.

**Cleaning logic**

The cleaning should:

1. remove leading and trailing spaces
2. replace empty strings with `NULL`
3. validate whether the value can be converted into a number
4. convert valid values into proper numeric data types
5. check whether values are within a realistic business range
6. flag invalid or unrealistic values for review



## 3.5 **Date Format and Date Validity Issue**

**Check purpose**

Date columns were checked to identify mixed date formats, missing date values, invalid date values, and values that cannot be safely converted into a proper `DATE` data type.

This check is important because date columns are needed for time-based analysis, such as sales trends, customer registration trends, order history, payment analysis, and Power BI date modelling.

**Result summary**

The check showed that some date columns are stored as `text` instead of proper date values.

Some date values may appear in different formats, for example:

| Example value | Issue |
|---|---|
| `2023-05-14` | Standard date format |
| `14/05/2023` | Slash-based date format |
| `05/14/2023` | Ambiguous slash-based date format |
| empty value | Missing date |
| invalid text value | Cannot be converted into a valid date |

Because of this, the affected columns cannot be reliably used as real dates without cleaning.

**Data quality issue**

Some date columns contain mixed formats, missing values, or invalid date values.

This can cause incorrect date conversion, wrong sorting, incorrect filtering, and unreliable time-based analysis.

For example, if a date value is interpreted in the wrong format, the month, year, or exact transaction date may be incorrect.

**Business impact**

This issue can affect reporting and analysis.

For example, sales trends by month, customer growth over time, order history, payment timing, and seasonal analysis may show incorrect results if date values are not cleaned properly.

It can also affect Power BI modelling because text-based date columns cannot be used properly for date relationships, time intelligence, or calendar-based analysis.

**Severity: High**

Date issues can directly affect time-based analysis, filtering, joins with date dimensions, reporting logic, and Power BI modelling.

**Cleaning decision**

The original date columns will not be changed in the raw tables.

Instead, cleaned date columns will be created in the cleaned tables.

Valid date values will be converted into the proper `DATE` data type.

Missing, invalid, or unrecognized date values will be set to `NULL`.

**Cleaning logic**

The cleaning should:

1. remove leading and trailing spaces
2. identify the existing date format
3. convert valid date values into a proper `DATE` data type
4. set missing or unrecognized values to `NULL`
5. optionally create a date quality status column for documentation

Possible status values:

* `valid`
* `missing`
* `invalid_format`


## 3.6 **Inconsistent Category Value Issue**

**Check purpose**

Categorical columns were checked to identify inconsistent category names, spelling variations, casing differences, and values that represent the same category in different ways.

This check is important because categorical columns are used for grouping, filtering, segmentation, and reporting.

**Result summary**

The check was used to confirm whether category values are stored consistently.

Examples of categorical columns:

| Table | Categorical column |
|---|---|
| customers | `gender` |
| customers | `marketing_channel` |
| products | `category` |
| orders | `order_status` |
| payments | `payment_method` |
| payments | `payment_status` |

**Data quality issue**

Some categorical values may be stored inconsistently.

The same category may appear in different spellings, different casing, or different formats.

For example, one payment method could appear as `Credit Card`, `credit_card`, and `CREDIT CARD`.

**Business impact**

This issue can lead to incorrect grouping and reporting.

For example, payment method analysis, product category analysis, customer segmentation, and order status reporting may show too many separate categories.

This makes reports harder to read and can lead to wrong business conclusions.

**Severity: Medium**

The issue usually does not break the data model, but it can strongly affect reporting and segmentation.

**Cleaning decision**

The original categorical columns will not be changed in the raw tables.

Cleaned category columns will be created or standardized in the cleaned tables.

Known category variants will be mapped to one consistent value.

Unknown values will be marked as `UNKNOWN` or set to `NULL`, depending on the business rule.

**Cleaning logic**

The cleaning should:

1. remove leading and trailing spaces
2. standardize casing
3. map known category variants to one standard value
4. identify unexpected category values
5. flag unknown values for review


## 3.7 **Boolean Value Inconsistency Issue**

**Check purpose**

Boolean columns were checked to identify inconsistent values that represent the same logical meaning.

This check is important because Boolean fields are used for filtering, grouping, and customer segmentation.

**Result summary**

The check showed that the `loyalty_member` column contains inconsistent values.

Examples of possible raw values:

| Raw value | Meaning |
|---|---|
| `Y` | loyalty member |
| `N` | not a loyalty member |
| `TRUE` | loyalty member |
| `FALSE` | not a loyalty member |
| `1` | loyalty member |
| `0` | not a loyalty member |

**Data quality issue**

The same Boolean meaning is stored in different formats.

Because of this, loyalty members may be split across multiple values instead of being grouped correctly.

**Business impact**

This issue can affect customer segmentation and loyalty analysis.

For example, if `Y`, `TRUE`, and `1` are not standardized, the number of loyalty members may be undercounted.

This can lead to incorrect analysis of loyalty member behavior, customer value, and marketing performance.

**Severity: High**

Boolean inconsistency can lead to wrong segmentation and incorrect business logic.

**Cleaning decision**

The original `loyalty_member` column will not be changed in the raw table.

A cleaned Boolean column will be created in the cleaned customer table.

The cleaned column should contain only:

* `TRUE`
* `FALSE`
* `NULL`

**Cleaning logic**

The cleaning should:

1. remove leading and trailing spaces
2. convert values to lowercase for comparison
3. map positive values such as `Y`, `TRUE`, and `1` to `TRUE`
4. map negative values such as `N`, `FALSE`, and `0` to `FALSE`
5. set unknown or missing values to `NULL`


## 3.8 **Whitespace and Text Formatting Issue**

**Check purpose**

Text columns were checked to identify leading spaces, trailing spaces, inconsistent casing, and formatting differences.

This check is important because text formatting issues can create duplicate-looking values and incorrect grouping results.

**Result summary**

The check was used to confirm whether text values are stored consistently across the raw tables.

Examples:

| Issue type | Example |
|---|---|
| Leading space | ` Germany` |
| Trailing space | `Germany ` |
| Inconsistent casing | `germany`, `Germany`, `GERMANY` |
| Empty string | `''` |
| Duplicate-looking value | `Berlin` and `Berlin ` |

**Data quality issue**

Some text columns may contain inconsistent formatting.

Even when values look similar to humans, SQL and Power BI may treat them as different values.

For example, `Germany`, `germany`, and `Germany ` can be counted as separate values if they are not cleaned.

**Business impact**

This issue can affect grouping, filtering, segmentation, and reporting.

It can lead to duplicated categories, wrong counts, and messy slicers in Power BI.

**Severity: Low to Medium**

The issue is usually easy to clean, but it can still affect reporting quality and user experience.

**Cleaning decision**

The raw text columns will not be changed.

Cleaned text columns will be standardized in the cleaned tables.

Leading and trailing spaces will be removed. Empty strings will be converted to `NULL`.

For selected categorical columns, casing will be standardized.

**Cleaning logic**

The cleaning should:

1. remove leading and trailing spaces
2. convert empty strings to `NULL`
3. standardize casing where needed
4. keep original business meaning
5. use cleaned text values for reporting and Power BI slicers

