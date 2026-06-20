# Data Model Documentation

## 1. Goal

The goal of this data model is to create an analysis-ready star schema for sales, customer, product, order, store, payment, date, and marketing analysis.

The model is designed to support business questions such as:

* revenue development over time
* customer and country performance
* product and category performance
* order and payment behavior
* return impact on revenue
* marketing campaign performance
* campaign-related revenue attribution

---

## 2. Model Overview


---

## 3. Dimension Tables

The model uses the following dimension tables:

| dimension table | description |
|---|---|
| `dim_customers` | Customer attributes such as customer ID, name, country, gender, registration date, and loyalty status |
| `dim_products` | Product attributes such as product name, category, brand, standard price, unit cost, launch date, and product quality flags |
| `dim_orders` | Order-level descriptive information such as order status, sales channel, shipping method, and order country |
| `dim_date` | Calendar attributes at day level, such as year, quarter, month, month name, weekday, and weekend flag |
| `dim_payment` | Descriptive payment attributes such as payment ID, payment method, provider, and payment type |
| `dim_return_reason` | Return reason attributes such as return reason, return reason category, and whether the reason was provided or unknown |
| `dim_marketing_campaigns` | Marketing campaign and channel information at campaign-channel level |                                               
---
 ### 1. Payment modelling decision

Payment data is split into a dimension table and a fact table.

`dim_payment` stores descriptive payment attributes, such as payment method, provider, and payment type.

`fact_payments` stores measurable payment events, such as payment amount, payment status, and transaction-level information.

This separation is necessary because payment data is not only descriptive. It also contains business events that can be analysed, for example failed payments, refunded payments, and payment amounts by method.

### 2. Return modelling decision

Return data is split into `dim_return_reason` and `fact_returns`.

`dim_return_reason` describes why an item was returned.  
Examples include damaged on arrival, wrong item, quality issue, or customer changed mind.

`fact_returns` stores the actual return event, such as the returned order item, return date, refund amount, and return quantity.

This keeps the model clean because the reason for a return is descriptive, while the return itself is a measurable business event.

### 3. Return modelling decision

Return data is split into `dim_return_reason` and `fact_returns`.

`dim_return_reason` describes why an item was returned.  
Examples include damaged on arrival, wrong item, quality issue, or customer changed mind.

`fact_returns` stores the actual return event, such as the returned order item, return date, refund amount, and return quantity.

This keeps the model clean because the reason for a return is descriptive, while the return itself is a measurable business event.

### 4. Date dimension decision

`dim_date` is created at day level.

Even if many analyses are later shown by month, quarter, or year, the fact tables usually contain exact dates. A day-level date dimension allows flexible analysis at different time levels.

Examples:

- daily sales
- monthly revenue
- quarterly growth
- weekday vs weekend performance
- return rate by month
- payment issues by date

### 5 Unknown Dimension Rows

Some dimension tables include an unknown fallback row with surrogate key `-1`.

This row is used when a fact record cannot be matched to a valid dimension record. Instead of deleting the fact record, the model keeps it and links it to the unknown row.

This protects the completeness of the analysis while making data quality issues visible.


## 4. Fact Tables

The model uses the following fact tables:

| fact table | grain | purpose |
|---|---|---|
| `fact_order_items` | One row per product line within one order | Main sales fact table for revenue, quantity, product, customer, and order analysis |
| `fact_payments` | One row per payment transaction | Used to analyse payment amounts, payment status, payment method performance, and payment issues |
| `fact_returns` | One row per returned order item or return event | Used to analyse returned items, return reasons, refund amounts, and return rates |
| `fact_marketing_touchpoints` | One row per marketing touchpoint | Used to analyse marketing campaign interactions and channel performance |

### 4.1 `fact_order_items`

The main sales fact table is `fact_order_items`.

**Grain:**

```text
One row represents one product line within one order.
```

This means that if one order contains three products, the fact table will contain three rows.

**Expected keys:**

```text
order_key
customer_key
product_key
date_key
payment_key
```

**Expected measures:**

```text
quantity
unit_price
discount_amount
line_revenue
line_cost
line_margin
```

This fact table supports sales, product, customer, store, payment, and return-related analysis.

---

### 4.2 `fact_marketing_touchpoints`

The marketing fact table is `fact_marketing_touchpoints`.

**Grain:**

```text
One row represents one marketing touchpoint between a customer and a campaign-channel combination on a specific date.
```

**Expected columns:**

```text
marketing_touchpoint_id
customer_key
campaign_key
date_key
clicked
converted
```

The `marketing_touchpoint_id` is kept in the fact table because it represents an individual marketing interaction event.

This fact table supports campaign performance analysis, such as clicks, conversions, and later revenue attribution.

---

## 5. Marketing Campaign Grain Decision

### Issue

During validation, the original column `campaign_id` showed the following result:

| metric                                 |  value |
| -------------------------------------- | -----: |
| total_rows                             | 12,000 |
| distinct_campaign_ids                  | 12,000 |
| distinct_campaign_names                |     14 |
| distinct_campaign_channel_combinations |     98 |

The result shows that `campaign_id` is unique for every row. Therefore, it does not represent a reusable marketing campaign. Instead, it represents one marketing interaction or touchpoint.

### Modelling decision

The raw column `campaign_id` is renamed to `marketing_touchpoint_id` in the staging layer.

The marketing campaign dimension is not created from `marketing_touchpoint_id`. Instead, the dimension is created at the following grain:

```text
One row per campaign name and channel combination.
```

The business key of `dim_marketing_campaigns` is therefore:

```text
campaign_name + channel
```

### Dimension table design

```text
mart.dim_marketing_campaigns
- campaign_key
- campaign_name
- channel
```

`campaign_key` is the surrogate key used to connect the campaign dimension with the marketing fact table.

### Fact table relationship

```text
mart.fact_marketing_touchpoints
- marketing_touchpoint_id
- customer_key
- campaign_key
- date_key
- clicked
- converted
```

### Reasoning

Using `marketing_touchpoint_id` as the campaign dimension key would create 12,000 dimension rows. This would make the dimension too detailed and not useful for campaign-level analysis.

By using `campaign_name + channel` as the campaign dimension grain, the model supports analysis such as:

* campaign performance by channel
* clicks and conversions by campaign
* revenue attribution by campaign and channel
* comparison of marketing channels

This keeps the dimension table small, descriptive, and aligned with the analytical business questions.

---

## 6. Unknown Product Decision

During validation, some product references could not be matched to valid product records.

### Modelling decision

Ghost product rows are mapped to an Unknown Product member in `dim_products`.

```text
product_key = -1
product_id = UNKNOWN
product_name = Unknown Product
```

These rows remain in `fact_order_items` so that total revenue and order-level analysis remain complete.

However, Unknown Product rows should be excluded or separated in product-, category-, and brand-level analysis because they cannot be assigned to a real product.

### Reasoning

Removing these rows would reduce the completeness of revenue analysis. Mapping them to an Unknown Product keeps the fact table complete while making the data quality issue visible in analysis.

---

## 7. Relationship Logic

The fact tables are connected through shared dimensions.

Example:

```text
fact_order_items
    -> customer_key
    -> dim_customers

fact_marketing_touchpoints
    -> customer_key
    -> dim_customers
```

This allows analysis across different business processes.

For example:

```text
Customers who clicked a campaign can later be compared with their sales behavior.
```

However, the two fact tables should not be joined directly without a clear business rule. For revenue attribution, a defined attribution logic is needed, such as:

```text
Last-click attribution within a 7-day window.
```
It means:
If a customer clicked a campaign, and then placed an order within the next 7 days, we give the revenue credit to the latest clicked campaign before the order.

This avoids duplicated revenue and makes the analysis explainable.

---

## 8. Main Business Questions

### Sales

* How much revenue do we generate?
* Which month has the highest sales?
* Which sales channel performs best?
* Which customers and countries generate the most sales?
* How do returns affect revenue?

### Customer

* Which countries have the most customers?
* Do loyalty customers spend more?
* What is the average order value?

### Product

* Which categories generate the most revenue?
* Which products sell often but have low margin?
* Are there products with suspicious prices?

### Operations

* Which shipping method is used most?
* Are returns concentrated in certain product categories?
* Which payment methods generate the most paid revenue?
* Which payment methods have the highest refund rate?
* Do BNPL/Klarna customers have higher average order value?
* How much revenue is pending and not yet safely received?

### Marketing

* Which campaigns generate the most clicks?
* Which campaigns generate the most conversions?
* Which marketing channels perform best?
* Which campaigns are associated with the most revenue after attribution?

---

## 9. Summary of Key Modelling Decisions

| topic                              | decision                                                        |
| ---------------------------------- | --------------------------------------------------------------- |
| Sales fact grain                   | one row per product line within one order                       |
| Marketing fact grain               | one row per customer-campaign-channel-date touchpoint           |
| Marketing campaign dimension grain | one row per campaign name and channel combination               |
| Original `campaign_id`             | renamed to `marketing_touchpoint_id` in staging                 |
| Unknown products                   | mapped to `product_key = -1`                                    |
| Ghost product rows                 | kept in fact table for complete revenue analysis                |
| Product-level analysis             | Unknown Product should be excluded or shown separately          |
| Multiple fact tables               | used because sales and marketing have different business grains |


## 10. Dimension Table Validation

### 10.1 Marketing Campaign Dimension Validation

After creating `mart.dim_marketing_campaigns`, the table was checked to confirm that the dimension was created correctly.

### Checks performed

The following checks were performed:

* preview of the dimension table
* total row count
* existence of the Unknown Campaign fallback row
* duplicate check for `campaign_name + channel`
* NULL check for key dimension columns
* comparison between staging campaign-channel combinations and dimension rows

### Result


| check | result |
|---|---:|
| Total rows in `dim_marketing_campaigns` | 99 |
| Unknown Campaign fallback rows | 1 |
| Duplicate `campaign_name + channel` combinations | 0 |
| NULL values in required columns | 0 |
| Unique campaign-channel combinations from staging | 98 |
| Expected dimension rows including Unknown row | 99 |

### Finding

The validation confirms that `mart.dim_marketing_campaigns` was created successfully at the campaign-channel grain.

The table contains one row per unique `campaign_name + channel` combination, plus one Unknown Campaign fallback row with `campaign_key = -1`.

No duplicate campaign-channel combinations or NULL values were found in the required columns.

### Modelling conclusion

`dim_marketing_campaigns` is ready to be used as a dimension table for the future `fact_marketing_touchpoints` table.






