# Business Metadata - Nordhome Retail Project

## 1. Purpose

This document defines the main business terms, KPIs, calculation rules, and analysis assumptions used in the Nordhome Retail project.

The goal is to make sure that business metrics such as revenue, order value, return rate, and customer activity are clearly defined and consistently used across SQL analysis, Python EDA, and Power BI dashboards.

---

## 2. Business Context

Nordhome Retail is a fictional pan-European e-commerce retailer selling home décor, kitchen, beauty, lifestyle, and gift products.

The dataset covers 10 European markets:

| Market | ISO code |
|---|---|
| Germany | DE |
| Austria | AT |
| Switzerland | CH |
| France | FR |
| Netherlands | NL |
| Belgium | BE |
| Sweden | SE |
| Denmark | DK |
| Norway | NO |
| Poland | PL |

The dataset spans January 2021 to June 2024 and contains approximately 166,000 rows with intentional data quality issues for cleaning and analysis practice.

The dataset represents typical retail processes:

* customers registering and placing orders
* products being sold through different channels
* orders containing one or more order items
* payments being made for orders
* products being returned

The business focus of this project is to analyze sales performance, customer behavior, product performance, returns, and potential revenue loss.

---

## 3. Business Entities

| Business Entity | Meaning                                                         |
| --------------- | --------------------------------------------------------------- |
| Customer        | A person who registered with Nordhome Retail or placed an order |
| Product         | An item sold by Nordhome Retail                                 |
| Order           | A customer purchase transaction                                 |
| Order Item      | One product line within an order                                |
| Payment         | A payment transaction linked to an order                        |
| Return          | A product returned by a customer                                |
| Store           | A physical or digital sales location                            |

---

## 4. Business Terms and Definitions

## Customer

A customer represents a person who can place orders.

Customers are identified by `customer_id` in the source data and by `customer_key` in the dimensional model.

Important note:

If `customer_key = -1`, the order exists but the customer could not be matched to a valid customer record.

This means the order can still be used for revenue analysis, but should be handled carefully in customer segmentation or retention analysis.

---

## Product

A product represents an item sold by Nordhome Retail.

Products are identified by `product_id` in the source data and by `product_key` in the dimensional model.

Important note:

If `product_key = -1`, the transaction contains a product that could not be matched to the product master table.

This may happen because of missing product records, ghost product IDs, deleted products, or source system issues.

---

## Order

An order represents a purchase made by a customer.

One order can contain one or more order items.

Business meaning:

An order should be used when analyzing order volume, average order value, customer purchase frequency, and sales trends.

---

## Order Item

An order item represents one product line within an order.

Example:

One order may contain:

* 1 candle
* 2 plates
* 1 vase

This would create three order item records.

Business meaning:

Order item level is the correct level for product sales analysis, category analysis, quantity analysis, and revenue calculation.

---

## Return

A return represents a product that was returned by a customer.

Returns are important for understanding product quality, customer satisfaction, and revenue risk.

Important note:

Return analysis should check whether the returned product and order can be matched correctly.

---

## 5. Key Business Metrics

## Revenue

| Field          | Definition                                                               |
| -------------- | ------------------------------------------------------------------------ |
| Business term  | Revenue                                                                  |
| Meaning        | Sales value generated from sold products                                 |
| Formula        | `quantity * unit_price`                                                  |
| Grain          | Order item level                                                         |
| Used for       | Sales trend, product performance, category performance, revenue analysis |
| Includes       | Valid sold order items                                                   |
| Excludes       | Records with invalid quantity or invalid price                           |
| Important note | Revenue is not the same as profit                                        |

Revenue measures the sales value before deducting product cost.

If return data is not deducted, this should be called gross revenue or sales revenue, not net revenue.

---

## Gross Revenue

| Field          | Definition                                                                  |
| -------------- | --------------------------------------------------------------------------- |
| Business term  | Gross Revenue                                                               |
| Meaning        | Revenue from orders that were actually charged — excludes Cancelled orders  |
| Formula        | `SUM(line_total) WHERE order_status NOT IN ('Cancelled')`                   |
| Covers         | Completed, Shipped, Processing, Refunded, Returned                          |
| Excludes       | Cancelled orders — no charge was ever made                                  |
| Used for       | Sales performance analysis, baseline for net revenue calculation            |
| Important note | Gross revenue may overstate actual performance if returns are high           |

---

## Net Revenue

| Field          | Definition                                                                                   |
| -------------- | -------------------------------------------------------------------------------------------- |
| Business term  | Net Revenue                                                                                  |
| Meaning        | Revenue after deducting actual cash refunded to customers                                    |
| Formula        | `SUM(line_total WHERE order_status NOT IN ('Cancelled')) − SUM(refund_amount FROM fact_returns)` |
| Used for       | P&L reporting, finance reporting, realistic business performance analysis                    |
| Important note | Use actual `refund_amount` from `fact_returns`, not status-based line_total deductions       |

### Revenue Calculation Methods — Decision Record

Two methods were evaluated for calculating net revenue:

| Method | Formula | Deducts |
|--------|---------|---------|
| **Method A** (status-based) | `SUM(line_total)` for non-bad-status orders | Full `line_total` of Cancelled + Refunded + Returned orders |
| **Method B** (cash-based) ✓ | Gross − `SUM(refund_amount)` | Actual cash refunded via `fact_returns` |

**Decision: Method B is the standard for this project.**

Reason: Method A systematically over-deducts because it subtracts the full line total of Cancelled orders (which were never charged) and the full line total of Refunded/Returned orders (which may have only been partially refunded). Analysis across 42 months (Jan 2021–Jun 2024) showed a consistent discrepancy of ~€89K/month between the two methods, split approximately:

- **~60% partial refund gap** — Refunded/Returned order `line_total` exceeded actual `refund_amount` (e.g. restocking fees, partial goodwill refunds)
- **~40% cancelled order value** — Cancelled orders deducted in full by Method A but not in `fact_returns` at all

Method A remains valid for **operational and fulfilment reporting** — e.g. measuring total order value at risk of reversal.

---

## Average Order Value

| Field          | Definition                                                         |
| -------------- | ------------------------------------------------------------------ |
| Business term  | Average Order Value                                                |
| Short name     | AOV                                                                |
| Meaning        | Average revenue generated per order                                |
| Formula        | `total_revenue / number_of_orders`                                 |
| Used for       | Customer behavior, sales performance, channel comparison           |
| Important note | Count orders with `COUNT(DISTINCT order_id)`, not simple row count |

Because the sales fact table may be at order item level, one order can appear multiple times.

Therefore, AOV should not be calculated by counting rows.

Correct logic:

```sql
SUM(total_revenue) / COUNT(DISTINCT order_id)
```

---

## Order Volume

| Field          | Definition                                         |
| -------------- | -------------------------------------------------- |
| Business term  | Order Volume                                       |
| Meaning        | Number of unique orders                            |
| Formula        | `COUNT(DISTINCT order_id)`                         |
| Used for       | Sales trend, demand analysis, seasonality analysis |
| Important note | Do not use simple `COUNT(*)` on order item level   |

---

## Units Sold

| Field          | Definition                                               |
| -------------- | -------------------------------------------------------- |
| Business term  | Units Sold                                               |
| Meaning        | Total number of product units sold                       |
| Formula        | `SUM(quantity)`                                          |
| Used for       | Product demand, inventory planning, category analysis    |
| Important note | Quantity should be checked for invalid or extreme values |

---

## Return Rate

| Field               | Definition                                                   |
| ------------------- | ------------------------------------------------------------ |
| Business term       | Return Rate                                                  |
| Meaning             | Share of sold items or orders that were returned             |
| Possible formula    | `returned_items / sold_items`                                |
| Alternative formula | `returned_orders / total_orders`                             |
| Used for            | Product quality analysis, customer satisfaction, return risk |
| Important note      | The exact formula must be stated clearly                     |

There are different ways to calculate return rate.

For product analysis, item-level return rate is more useful.

For customer or order behavior, order-level return rate may be more useful.

---

## Customer Lifetime Value

| Field          | Definition                                                  |
| -------------- | ----------------------------------------------------------- |
| Business term  | Customer Lifetime Value                                     |
| Short name     | CLV                                                         |
| Meaning        | Total revenue generated by a customer over time             |
| Formula        | `SUM(customer revenue)`                                     |
| Used for       | Customer value analysis, loyalty analysis, segmentation     |
| Important note | This is a simplified CLV if future revenue is not predicted |

In this project, CLV is calculated historically based on available order data.

It is not a predictive lifetime value model unless machine learning is added later.

---

## Churn Risk

| Field              | Definition                                                                 |
| ------------------ | -------------------------------------------------------------------------- |
| Business term      | Churn Risk                                                                 |
| Meaning            | Estimated risk that a customer will stop buying                            |
| Possible rule      | Customer has not ordered for a long period                                 |
| Possible ML target | Customer did not make another purchase within a defined future time window |
| Used for           | Customer retention, revenue loss prediction                                |
| Important note     | Churn must be defined clearly before modelling                             |

Example business definition:

A customer is considered at churn risk if they have not placed an order in the last 90 days.

This rule can be adjusted depending on the business model and average purchase cycle.

---

## Revenue Loss from Churn Risk

| Field            | Definition                                                            |
| ---------------- | --------------------------------------------------------------------- |
| Business term    | Revenue Loss from Churn Risk                                          |
| Meaning          | Estimated revenue that may be lost if high-risk customers stop buying |
| Possible formula | `churn_probability * expected_future_revenue`                         |
| Used for         | Retention prioritization, customer risk analysis                      |
| Important note   | This is an estimate, not an exact value                               |

Example:

If a customer has an expected future revenue of €200 and a churn probability of 60%, the expected revenue loss is:

```text
200 * 0.60 = 120
```

Estimated revenue loss: €120

---

## 6. Business Rules

| Rule                                                         | Explanation                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| Cancelled orders should not be counted as completed sales    | They do not represent successful revenue                     |
| Invalid prices should be flagged                             | They can distort revenue and margin analysis                 |
| Unknown customers should not be removed automatically        | Their orders may still be valid for revenue analysis         |
| Unknown products should be flagged                           | Product performance analysis needs valid product information |
| Return data should be checked before net revenue calculation | Incomplete return data can create misleading results         |
| Duplicate customers should be handled carefully              | They can distort customer count, loyalty analysis, and CLV   |
| Revenue is not profit                                        | Cost must be deducted before talking about profit            |

---

## 7. Analysis Assumptions

| Topic                   | Assumption                                                  |
| ----------------------- | ----------------------------------------------------------- |
| Revenue analysis        | Uses valid order item records with valid price and quantity |
| Customer analysis       | Requires valid customer information                         |
| Product analysis        | Requires valid product information                          |
| Return analysis         | Requires valid return, order, and product relationships     |
| AOV analysis            | Uses unique order count                                     |
| Churn analysis          | Requires a clear inactivity period or prediction window     |
| Revenue loss prediction | Requires expected future revenue and churn probability      |

---

## 8. Handling Unknown Records

Unknown records are kept instead of deleted.

This supports traceability and prevents silent data loss.

| Unknown Case        | Business Meaning                       | Recommended Handling                                                      |
| ------------------- | -------------------------------------- | ------------------------------------------------------------------------- |
| `customer_key = -1` | Customer could not be matched          | Keep for revenue analysis, exclude from customer segmentation             |
| `product_key = -1`  | Product could not be matched           | Keep for revenue analysis if price is valid, exclude from product ranking |
| `store_key = -1`    | Store could not be matched             | Keep for overall sales, exclude from store-level analysis                 |
| Missing date        | Transaction date is unknown or invalid | Exclude from time series analysis                                         |

---

## 9. Quality Flags and Business Impact

| Flag                        | Business Meaning                                                   | Possible Impact                                         |
| --------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------- |
| `email_quality_issue`       | Email is missing or invalid                                        | Customer communication analysis may be affected         |
| `phone_quality_issue`       | Phone number is missing or invalid                                 | Low impact unless phone contact is analyzed             |
| `price_quality_issue`       | Product price information is inconsistent                          | Revenue or margin analysis may be distorted             |
| `ghost_product_flag`        | Product appears in transaction data but not in product master data | Product analysis may be incomplete                      |
| `unknown_customer_flag`     | Customer could not be matched                                      | Customer segmentation may be incomplete                 |
| `unknown_product_flag`      | Product could not be matched                                       | Product ranking and category analysis may be incomplete |
| `referential_quality_issue` | Relationship between tables is broken                              | Joins may produce missing or misleading results         |

---

## 10. Recommended Metric Usage

| Business Question                             | Recommended Metric             | Notes                                                     |
| --------------------------------------------- | ------------------------------ | --------------------------------------------------------- |
| How much did we sell?                         | Revenue                        | Check order status and price validity                     |
| How many orders did we receive?               | Order Volume                   | Use distinct order count                                  |
| How much does each order generate on average? | AOV                            | Use revenue divided by distinct orders                    |
| Which products perform best?                  | Revenue by product, units sold | Exclude unknown products if product attributes are needed |
| Which categories perform best?                | Revenue by category            | Requires valid product-category mapping                   |
| Which customers are most valuable?            | CLV                            | Requires valid customer matching                          |
| Which customers may churn?                    | Churn risk                     | Requires clear churn definition                           |
| How much revenue is at risk?                  | Expected revenue loss          | Requires churn probability and expected future revenue    |
| Which products are returned often?            | Return rate                    | Requires reliable return data                             |

---

## 11. Business Owners

Because this is a portfolio project, business owners are simulated.

| Area         | Simulated Business Owner      |
| ------------ | ----------------------------- |
| Revenue      | Finance / Sales               |
| Orders       | Sales Operations              |
| Customers    | CRM / Marketing               |
| Products     | Product Management            |
| Returns      | Customer Service / Operations |
| Payments     | Finance                       |
| Data Quality | Data / Analytics Team         |

---

## 12. Notes for Dashboard Interpretation

Dashboard users should be aware that:

* revenue may not equal profit
* gross revenue may not deduct returns
* AOV must be based on unique orders
* unknown customers and products can affect segmentation
* quality flags should be considered before making business decisions
* return data must be reliable before calculating net revenue
* churn risk is an analytical estimate, not a confirmed customer decision

---

## 13. Update Log

| Date       | Change                                     |
| ---------- | ------------------------------------------ |
| 2026-06-20 | Added market list (10 European markets, confirmed Poland not Finland); updated business context |
| 2026-06-23 | Updated Gross Revenue and Net Revenue definitions; added Method A vs Method B decision record — Method B (cash-based, using `refund_amount` from `fact_returns`) adopted as project standard for P&L reporting |
