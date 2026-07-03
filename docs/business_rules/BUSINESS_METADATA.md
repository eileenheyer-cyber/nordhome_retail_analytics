# Business Metadata - Nordhome Retail Project

## 1. Purpose

This document defines the main business terms, KPIs, calculation rules, and analysis assumptions used in the Nordhome Retail project.

The goal is to make sure that business metrics such as revenue, order value, return rate, customer activity, and revenue risk are clearly defined and consistently used across SQL analysis, Python EDA, and Power BI dashboards.

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

This means the order can still be used for overall revenue analysis, but should be handled carefully or excluded in customer segmentation, retention, churn, and CLV analysis.

---

## Product

A product represents an item sold by Nordhome Retail.

Products are identified by `product_id` in the source data and by `product_key` in the dimensional model.

Important note:

If `product_key = -1`, the transaction contains a product that could not be matched to the product master table.

This may happen because of missing product records, ghost product IDs, deleted products, or source system issues.

The transaction may still be valid for total revenue analysis if price and quantity are valid, but it should not be used for product ranking or category analysis that requires reliable product attributes.

---

## Order

An order represents a purchase made by a customer.

One order can contain one or more order items.

Business meaning:

An order should be used when analyzing order volume, average order value, customer purchase frequency, and sales trends.

Important note:

Order-level metrics must use `COUNT(DISTINCT order_id)` if the fact table is at order-item level.

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

Returns are important for understanding product quality, customer satisfaction, operational issues, and revenue risk.

Return and refund are treated as separate business concepts. A return describes the product coming back, while a refund describes money being paid back to the customer. These are related but not the same: a customer may return a product without receiving a full refund, or receive a refund without returning the product.

For revenue calculations, monetary refund amounts should be preferred where available. The actual `refund_amount` from `fact_returns` is a more precise measure of financial impact than deducting the full `line_total` based on order status alone.

Order statuses such as `Returned` and `Refunded` require stakeholder clarification because they may represent operational states, financial deductions, or both. Until clarified, these statuses should not be treated as equivalent to the `refund_amount` in `fact_returns`.

Important note:

Return analysis should check whether the returned product and order can be matched correctly.

Return data should be validated before it is used in net revenue, return rate, or product quality analysis.

---

## 5. General Metric Assumptions

| Topic | Assumption |
|---|---|
| Currency | Monetary values are treated as EUR unless stated otherwise |
| VAT / sales tax | Revenue metrics should normally be reported excluding VAT |
| Cost | Product cost is not deducted from revenue; it is used for profit and margin analysis |
| Cancelled orders | Cancelled orders are excluded from revenue because they do not represent successful sales |
| Invalid quantity or price | Records with invalid quantity or invalid price should be excluded from revenue and margin KPIs |
| Unknown customer/product/store keys | Unknown records are kept for traceability but may be excluded from detailed dimensional analysis |

Important VAT note:

If `unit_price` and `line_total` already exclude VAT, they can be used directly for revenue calculation.

If source prices include VAT, VAT must be removed before calculating revenue:

```text
net_price_excluding_vat = gross_price_including_vat / (1 + vat_rate)
```

For this project, the default assumption is:

```text
unit_price and line_total are treated as values excluding VAT.
```

This keeps revenue, profit, and margin calculations separate from tax reporting.

---

## Revenue Definition

Gross revenue excludes cancelled orders.

Financial net revenue is calculated as:

```text
Financial Net Revenue = Gross Revenue - Actual Refund Amount
```

---

## 6. Key Business Metrics

## Sales Revenue

| Field          | Definition                                                               |
| -------------- | ------------------------------------------------------------------------ |
| Business term  | Sales Revenue                                                            |
| Meaning        | Sales value generated from sold products before returns and refunds       |
| Formula        | `quantity * unit_price`                                                  |
| Grain          | Order item level                                                         |
| Used for       | Sales trend, product performance, category performance, revenue analysis |
| Includes       | Valid sold order items                                                   |
| Excludes       | Records with invalid quantity or invalid price                           |
| VAT treatment  | Excluding VAT                                                            |
| Cost treatment | Product cost is not deducted                                             |
| Important note | Revenue is not the same as profit                                        |

Sales revenue measures the sales value before deducting product cost.

If return data is not deducted, this should be called sales revenue or gross sales revenue, not net revenue.

---

## Gross Sales Revenue

| Field          | Definition                                                                                           |
| -------------- | ---------------------------------------------------------------------------------------------------- |
| Business term  | Gross Sales Revenue                                                                                  |
| Meaning        | Revenue from non-cancelled order items before refunds and returns are deducted                        |
| Formula        | `SUM(line_total) WHERE order_status NOT IN ('Cancelled')`                                            |
| Covers         | Completed, Shipped, Processing, Refunded, Returned                                                    |
| Excludes       | Cancelled orders, invalid quantity, invalid price                                                     |
| VAT treatment  | Excluding VAT                                                                                        |
| Cost treatment | Product cost is not deducted                                                                         |
| Used for       | Sales performance analysis, demand analysis, baseline for net revenue calculation                     |
| Important note | Gross sales revenue may overstate actual business performance if refunds and returns are high         |

Business assumption:

`Processing` orders are included only under the assumption that payment was successfully captured.

If payment has not yet been captured, `Processing` orders should be analyzed separately as order value or open order value, not confirmed revenue.

---

## Cash-Based Net Revenue

| Field          | Definition                                                                                              |
| -------------- | ------------------------------------------------------------------------------------------------------- |
| Business term  | Cash-Based Net Revenue                                                                                  |
| Meaning        | Revenue after deducting actual cash refunded to customers                                                |
| Formula        | `SUM(line_total WHERE order_status NOT IN ('Cancelled')) - SUM(refund_amount FROM fact_returns)`         |
| Excludes       | Cancelled orders, invalid quantity, invalid price, actual refund amounts                                 |
| VAT treatment  | Excluding VAT                                                                                           |
| Cost treatment | Product cost is not deducted                                                                            |
| Used for       | Finance reporting, realistic business performance analysis, dashboard revenue KPI                        |
| Important note | Use actual `refund_amount` from `fact_returns`, not full status-based line total deductions              |

Net revenue is not profit.

Product cost is not deducted from net revenue. Product cost is used later for gross profit and gross margin calculation.

### Revenue Calculation Methods — Decision Record

Two methods were evaluated for calculating net revenue:

| Method | Formula | Deducts | Main Use |
|--------|---------|---------|---------|
| **Method A**: Status-based deduction | `SUM(line_total)` excluding Cancelled, Refunded, and Returned orders | Full `line_total` of Cancelled + Refunded + Returned orders | Operational risk view |
| **Method B**: Cash-based deduction ✓ | Gross Sales Revenue - `SUM(refund_amount)` | Actual cash refunded via `fact_returns` | Standard project net revenue KPI |

**Decision: Method B is the standard for this project.**

Reason:

Method A systematically over-deducts because it subtracts the full line total of cancelled orders, refunded orders, and returned orders.

This can be misleading because:

* Cancelled orders were never charged.
* Refunded or returned orders may only be partially refunded.
* Actual refund amount is a more precise measure of financial reversal.

Analysis across 42 months from January 2021 to June 2024 showed a consistent discrepancy of approximately €89K per month between the two methods, split approximately:

* approximately 60% partial refund gap — refunded or returned order `line_total` exceeded actual `refund_amount`
* approximately 40% cancelled order value — cancelled orders were deducted in full by Method A but did not appear in `fact_returns`

Method A remains useful for operational and fulfilment reporting, for example measuring total order value at risk of reversal.

Method B is used for finance-style net revenue reporting in this project.

---

## Gross Profit

| Field          | Definition                                               |
| -------------- | -------------------------------------------------------- |
| Business term  | Gross Profit                                             |
| Meaning        | Profit after deducting product cost from net revenue     |
| Formula        | `cash_based_net_revenue - cost_of_goods_sold`            |
| Used for       | Product profitability, category profitability, margin analysis |
| Important note | Gross profit is different from net revenue               |

Gross profit should only be calculated if product cost data is available and reliable.

For this project, product cost should be treated separately from revenue.

---

## Gross Margin

| Field          | Definition                                               |
| -------------- | -------------------------------------------------------- |
| Business term  | Gross Margin                                             |
| Meaning        | Share of net revenue left after product cost             |
| Formula        | `(cash_based_net_revenue - cost_of_goods_sold) / cash_based_net_revenue` |
| Used for       | Profitability analysis, category comparison, pricing analysis |
| Important note | Margin should not be calculated using VAT-inclusive revenue |

Example:

```text
Cash-based net revenue: €100
Product cost:           €45
Gross profit:           €55
Gross margin:           55%
```

---

## Average Order Value

| Field          | Definition                                                         |
| -------------- | ------------------------------------------------------------------ |
| Business term  | Average Order Value                                                |
| Short name     | AOV                                                                |
| Meaning        | Average revenue generated per order                                |
| Grain          | Order level                                                        |
| Used for       | Customer behavior, sales performance, channel comparison           |
| Important note | Count orders with `COUNT(DISTINCT order_id)`, not simple row count |

Because the sales fact table may be at order-item level, one order can appear multiple times.

Therefore, AOV should not be calculated by counting rows.

Recommended formulas:

```sql
Gross AOV = SUM(gross_sales_revenue) / COUNT(DISTINCT order_id)

Net AOV = SUM(cash_based_net_revenue) / COUNT(DISTINCT order_id)
```

Business interpretation:

* Gross AOV shows average basket value before refunds.
* Net AOV shows average realized order value after refunds.

Both can be useful, but the dashboard must clearly label which version is used.

---

## Order Volume

| Field          | Definition                                         |
| -------------- | -------------------------------------------------- |
| Business term  | Order Volume                                       |
| Meaning        | Number of unique orders                            |
| Formula        | `COUNT(DISTINCT order_id)`                         |
| Used for       | Sales trend, demand analysis, seasonality analysis |
| Important note | Do not use simple `COUNT(*)` on order item level   |

Business assumption:

Cancelled orders should usually be excluded from completed order volume.

If the business question is about total demand or operational workload, cancelled orders can be counted separately as placed orders.

Recommended distinction:

```text
Placed Orders = all unique orders
Completed Orders = unique orders excluding Cancelled
Cancelled Orders = unique orders with status Cancelled
```

---

## Units Sold

| Field          | Definition                                               |
| -------------- | -------------------------------------------------------- |
| Business term  | Units Sold                                               |
| Meaning        | Total number of product units sold                       |
| Used for       | Product demand, inventory planning, category analysis    |
| Important note | Quantity should be checked for invalid or extreme values |

Recommended formulas:

```sql
Gross Units Sold = SUM(quantity) for non-cancelled order items

Net Units Sold = Gross Units Sold - returned_quantity
```

Business interpretation:

* Gross units sold shows demand before returns.
* Net units sold shows realized sales volume after returns.

If returned quantity is not available, use gross units sold and clearly document that returns are not deducted.

---

## Return Rate

| Field               | Definition                                                   |
| ------------------- | ------------------------------------------------------------ |
| Business term       | Return Rate                                                  |
| Meaning             | Share of sold items, orders, or revenue that was returned or refunded |
| Used for            | Product quality analysis, customer satisfaction, return risk |
| Important note      | The exact formula must be stated clearly                     |

There are different ways to calculate return rate.

Recommended formulas:

```sql
Item Return Rate = returned_items / sold_items

Order Return Rate = returned_orders / total_orders

Revenue Return Rate = refund_amount / gross_sales_revenue
```

Business interpretation:

* Item return rate is useful for product-level analysis.
* Order return rate is useful for customer and operational behavior.
* Revenue return rate is useful for financial impact analysis.

For product analysis, item-level return rate is usually more useful.

For customer behavior analysis, order-level return rate may be more useful.

For financial reporting, revenue return rate gives a better view of monetary impact.

---

## Historical Customer Lifetime Value

| Field          | Definition                                                  |
| -------------- | ----------------------------------------------------------- |
| Business term  | Historical Customer Lifetime Value                          |
| Short name     | Historical CLV                                              |
| Meaning        | Total net revenue generated by a customer in the available dataset |
| Formula        | `SUM(cash_based_net_revenue) GROUP BY customer_id`           |
| Used for       | Customer value analysis, loyalty analysis, segmentation     |
| Important note | This is historical customer value, not predictive lifetime value |

In this project, CLV is calculated historically based on available order data.

It is not a predictive lifetime value model unless machine learning or future revenue estimation is added later.

Important note:

Customers with `customer_key = -1` should not be included in customer-level CLV, segmentation, or retention analysis because they cannot be reliably assigned to a known customer.

---

## Predicted Customer Lifetime Value

| Field          | Definition                                                                 |
| -------------- | --------------------------------------------------------------------------- |
| Business term  | Predicted Customer Lifetime Value                                          |
| Short name     | Predicted CLV / LTV                                                        |
| Meaning        | Estimated future value a customer is expected to generate, based on observed purchase behavior |
| Formula        | `Average Order Value x Purchase Frequency x Customer Lifespan` (heuristic method) |
| Grain          | Customer level (or customer segment level, e.g. age group, loyalty status) |
| Used for       | Retention prioritization, marketing spend allocation, forward-looking customer segmentation |
| Important note | This is an estimate, not a guaranteed future value                        |

Predicted CLV is the forward-looking counterpart to Historical CLV above.

Where Historical CLV answers *"what has this customer spent so far?"*, Predicted CLV answers *"what is this customer likely to spend in the future?"*

Important note on Customer Lifespan:

Customer Lifespan cannot be observed directly for customers who are still active, because their final purchase date is unknown (a censored observation). Any lifespan value used in the formula is an estimate, not a measured fact, and must be documented clearly wherever it is used.

Important note:

The same exclusion rules as Historical CLV apply: customers with `customer_key = -1` should not be included in Predicted CLV analysis.

See `05_customer_analysis/customer_ltv_prediction.ipynb` for the working analysis.

---

## Churn Risk

| Field              | Definition                                                                 |
| ------------------ | -------------------------------------------------------------------------- |
| Business term      | Churn Risk                                                                 |
| Meaning            | Estimated risk that a customer will stop buying                            |
| Possible rule      | Customer has not ordered within a defined inactivity threshold              |
| Possible ML target | Customer did not make another purchase within a defined future time window |
| Used for           | Customer retention, revenue risk analysis                                  |
| Important note     | Churn must be defined clearly before modelling                             |

Example business definition:

```text
A customer is considered at churn risk if they have not placed an order within the defined inactivity threshold.
```

Possible thresholds:

| Threshold | Possible interpretation |
|---|---|
| 90 days | Short-cycle products or frequent repeat purchase behavior |
| 180 days | Medium-cycle lifestyle or beauty purchase behavior |
| 365 days | Long-cycle home décor or seasonal purchase behavior |

For Nordhome Retail, a 90-day churn rule can be used as a simple starting point, but it should be validated against the average purchase cycle.

---

## Potential Revenue at Risk

| Field            | Definition                                                            |
| ---------------- | --------------------------------------------------------------------- |
| Business term    | Potential Revenue at Risk                                             |
| Meaning          | Estimated future revenue that may be lost if high-risk customers stop buying |
| Possible formula | `churn_probability * expected_future_revenue`                         |
| Used for         | Retention prioritization, customer risk analysis                      |
| Important note   | This is an estimate, not an exact value                               |

If no machine learning model is available, this metric should be treated as a simple business estimate.

If a churn model is added later, the metric can be calculated as:

```text
expected_revenue_loss = churn_probability * expected_future_revenue
```

Example:

If a customer has an expected future revenue of €200 and a churn probability of 60%, the expected revenue loss is:

```text
200 * 0.60 = 120
```

Estimated revenue loss: €120

Important note:

This metric should not be interpreted as confirmed revenue loss. It is a prioritization metric for retention analysis.

---

## 7. Business Rules

| Rule                                                         | Explanation                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| Cancelled orders should not be counted as completed sales    | They do not represent successful revenue                     |
| Processing orders should be interpreted carefully            | They should only be counted as revenue if payment was captured |
| Revenue should exclude VAT                                   | VAT is collected for tax authorities and should not be treated as business revenue |
| Cost should not be deducted from revenue                     | Cost is deducted only when calculating gross profit or margin |
| Invalid prices should be flagged                             | They can distort revenue and margin analysis                 |
| Invalid quantity should be flagged                           | It can distort units sold, revenue, and product demand analysis |
| Unknown customers should not be removed automatically        | Their orders may still be valid for overall revenue analysis |
| Unknown products should be flagged                           | Product performance analysis needs valid product information |
| Return data should be checked before net revenue calculation | Incomplete return data can create misleading results         |
| Duplicate customers should be handled carefully              | They can distort customer count, loyalty analysis, and historical CLV |
| Revenue is not profit                                        | Cost must be deducted before talking about profit            |
| Net revenue is not gross margin                              | Gross margin requires product cost deduction                 |

---

## 8. Analysis Assumptions

| Topic                   | Assumption                                                  |
| ----------------------- | ----------------------------------------------------------- |
| Revenue analysis        | Uses valid order item records with valid price and quantity |
| VAT treatment           | Revenue KPIs are treated as excluding VAT                   |
| Cost treatment          | Product cost is used only for profit and margin analysis    |
| Customer analysis       | Requires valid customer information                         |
| Product analysis        | Requires valid product information                          |
| Return analysis         | Requires valid return, order, and product relationships     |
| AOV analysis            | Uses unique order count                                     |
| Units sold analysis     | Should distinguish gross units sold and net units sold if return quantity is available |
| Churn analysis          | Requires a clear inactivity period or prediction window     |
| Revenue risk estimation | Requires expected future revenue and, if model-based, churn probability |

---

## 9. Handling Unknown Records

Unknown records are kept instead of deleted.

This supports traceability and prevents silent data loss.

| Unknown Case        | Business Meaning                       | Recommended Handling                                                      |
| ------------------- | -------------------------------------- | ------------------------------------------------------------------------- |
| `customer_key = -1` | Customer could not be matched          | Keep for overall revenue analysis, exclude from customer segmentation, CLV, retention, and churn analysis |
| `product_key = -1`  | Product could not be matched           | Keep for total revenue analysis if price is valid, exclude from product ranking and category analysis |
| `store_key = -1`    | Store could not be matched             | Keep for overall sales, exclude from store-level analysis                 |
| Missing date        | Transaction date is unknown or invalid | Exclude from time series analysis                                         |

---

## 10. Quality Flags and Business Impact

| Flag                        | Business Meaning                                                   | Possible Impact                                         |
| --------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------- |
| `email_quality_issue`       | Email is missing or invalid                                        | Customer communication analysis may be affected         |
| `phone_quality_issue`       | Phone number is missing or invalid                                 | Low impact unless phone contact is analyzed             |
| `price_quality_issue`       | Product price information is inconsistent                          | Revenue or margin analysis may be distorted             |
| `quantity_quality_issue`    | Quantity is invalid, missing, or extreme                           | Units sold and revenue analysis may be distorted        |
| `ghost_product_flag`        | Product appears in transaction data but not in product master data | Product analysis may be incomplete                      |
| `unknown_customer_flag`     | Customer could not be matched                                      | Customer segmentation may be incomplete                 |
| `unknown_product_flag`      | Product could not be matched                                       | Product ranking and category analysis may be incomplete |
| `referential_quality_issue` | Relationship between tables is broken                              | Joins may produce missing or misleading results         |

---

## 11. Recommended Metric Usage

| Business Question                             | Recommended Metric             | Notes                                                     |
| --------------------------------------------- | ------------------------------ | --------------------------------------------------------- |
| How much did we sell before refunds?          | Gross Sales Revenue            | Exclude cancelled orders and invalid price or quantity    |
| How much revenue did we keep after refunds?   | Cash-Based Net Revenue         | Deduct actual `refund_amount` from `fact_returns`         |
| How profitable are products or categories?    | Gross Profit / Gross Margin    | Requires reliable product cost                            |
| How many orders did we receive?               | Placed Orders                  | Count all unique orders if measuring demand               |
| How many orders were successfully sold?       | Completed Orders               | Count unique non-cancelled orders                         |
| How much does each order generate on average before refunds? | Gross AOV       | Gross Sales Revenue divided by distinct non-cancelled orders |
| How much does each order generate on average after refunds?  | Net AOV         | Cash-Based Net Revenue divided by distinct non-cancelled orders |
| Which products perform best?                  | Gross Sales Revenue by product, Gross Units Sold | Exclude unknown products if product attributes are needed |
| Which categories perform best?                | Revenue by category, Gross Margin by category | Requires valid product-category mapping and cost for margin |
| Which products create high refund impact?     | Revenue Return Rate            | Refund amount divided by gross sales revenue              |
| Which products are returned often?            | Item Return Rate               | Requires reliable return data                             |
| Which customers are most valuable so far?     | Historical CLV                 | Requires valid customer matching                          |
| Which customers are likely to be most valuable in the future? | Predicted CLV  | Heuristic estimate; requires a documented lifespan assumption |
| Which customers may churn?                    | Churn Risk                     | Requires clear inactivity threshold or prediction window  |
| How much revenue is at risk?                  | Potential Revenue at Risk      | Requires expected future revenue and, if model-based, churn probability |

---

## 12. Business Owners

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

## 13. Notes for Dashboard Interpretation

Dashboard users should be aware that:

* revenue may not equal profit
* revenue should normally exclude VAT
* gross sales revenue does not deduct refunds or returns
* cash-based net revenue deducts actual refund amounts, not full returned order value
* net revenue is not gross margin
* gross profit and gross margin require product cost
* AOV must be based on unique orders
* gross AOV and net AOV answer different questions
* gross units sold and net units sold answer different questions
* unknown customers and products can affect segmentation
* quality flags should be considered before making business decisions
* return data must be reliable before calculating net revenue or return rate
* churn risk is an analytical estimate, not a confirmed customer decision
* potential revenue at risk is a prioritization metric, not guaranteed revenue loss

---

## 14. Update Log

| Date       | Change                                     |
| ---------- | ------------------------------------------ |
| 2026-06-20 | Added market list: 10 European markets, confirmed Poland not Finland; updated business context |
| 2026-06-23 | Updated Gross Revenue and Net Revenue definitions; added Method A vs Method B decision record — Method B, cash-based using `refund_amount` from `fact_returns`, adopted as project standard for net revenue reporting |
| 2026-06-24 | Added VAT and cost assumptions; renamed revenue KPIs for clearer business meaning; added Gross Profit, Gross Margin, Gross AOV, Net AOV, Gross Units Sold, Net Units Sold, Historical CLV, and Potential Revenue at Risk definitions |
| 2026-07-03 | Added Predicted Customer Lifetime Value definition (heuristic: AOV x Frequency x Lifespan) as the forward-looking counterpart to Historical CLV; noted censoring limitation on lifespan; linked to `customer_ltv_prediction.ipynb` |
