# Revenue Deduction Logic: Net Revenue Definition

## Business Question

How much do returns, refunds, and cancellations reduce gross revenue — and how does net revenue trend year over year?

## Context

The dataset contains several fields that can influence revenue calculation:

* `order_status = 'Cancelled'`
* `order_status = 'Returned'`
* `order_status = 'Refunded'`
* `fact_returns.refund_amount`

At first, it was unclear whether all of these should be treated as financial deductions from gross revenue.

The main ambiguity was:

* Should cancelled orders be included in gross revenue and then deducted?
* Should returned and refunded order statuses reduce revenue by the full order value?
* Or should actual refund amounts from `fact_returns.refund_amount` be used for net revenue?

Because these fields represent different business concepts, the revenue logic required validation before final modelling.

---

## Business Concepts

In normal business practice, these concepts are not the same:

| Concept         | Meaning                               | Typical financial impact                                           |
| --------------- | ------------------------------------- | ------------------------------------------------------------------ |
| Cancelled order | Order was stopped before completion   | Usually excluded from realized revenue                             |
| Returned order  | Product was sent back by the customer | May lead to full refund, partial refund, exchange, or store credit |
| Refunded order  | Money was paid back to the customer   | Usually financial deduction                                        |
| Refund amount   | Actual monetary value refunded        | Strongest available signal for financial deduction                 |

A return and a refund are related, but they are not identical.

A returned order does not always mean the full order value was refunded.

---

## Validation Purpose

The purpose of the validation was to check whether order statuses and refund amounts can be used directly to calculate net revenue.

The validation compared two possible methods:

### Method A: Status-Based Deduction

```text
Net Revenue
= Gross Revenue
- Returned Order Value
- Refunded Order Value
```

This method assumes that returned and refunded orders should be deducted using the full order value.

### Method B: Refund-Amount-Based Deduction

```text
Net Revenue
= Gross Revenue
- Actual Refund Amount
```

This method uses the monetary refund value from `fact_returns.refund_amount`.

---

## Validation Result

| Year | Gross Revenue | Cancelled Excluded | Returned Value | Refunded Value | Net Method B | Net Method A | Difference B - A |
| ---: | ------------: | -----------------: | -------------: | -------------: | -----------: | -----------: | ---------------: |
| 2021 |     7,126,655 |            462,760 |        361,725 |        410,314 |    6,946,356 |    6,354,616 |         +591,740 |
| 2022 |     7,172,943 |            610,567 |        327,198 |        358,481 |    6,987,593 |    6,487,264 |         +500,329 |
| 2023 |     7,003,915 |            497,249 |        365,553 |        394,889 |    6,824,166 |    6,243,472 |         +580,694 |
| 2024 |     3,529,067 |            257,949 |        196,214 |        193,164 |    3,439,171 |    3,139,688 |         +299,483 |

---

## Key Findings

### 1. Cancelled orders are already excluded from gross revenue

The validation confirmed that cancelled orders are not part of the gross revenue used for analysis.

The revenue calculation already applies logic equivalent to:

```sql
WHERE order_status NOT IN ('Cancelled')
```

Therefore, cancelled order value should not be deducted again from gross revenue.

If cancelled orders were subtracted again, the model would double-count the cancellation impact.

### 2. Returned and refunded order value is higher than actual refund amount

The validation showed that the full order value of `Returned` and `Refunded` orders is consistently higher than the actual recorded refund amount.

Method B is around €300K–€590K higher than Method A depending on the year.

This suggests that using the full order value of returned/refunded orders as a deduction would overstate the deduction amount.

Possible business explanations:

* partial refunds
* exchanges
* store credit
* returned items that were not fully refunded
* operational status not equal to financial deduction
* incomplete or separate refund process

### 3. Order status should not automatically be treated as financial deduction

The fields `Returned` and `Refunded` are useful for operational analysis, but they should not automatically be used as full-value financial deductions unless confirmed by stakeholders.

The actual refund amount is a stronger monetary signal for financial net revenue.

---

## Final Modelling Decision

For financial revenue analysis, the project will use the following definition:

```text
Financial Net Revenue
= Gross Revenue excluding cancelled orders
- Actual Refund Amount
```

Cancelled orders are excluded from gross revenue.

Returned and refunded statuses are not deducted using full order value in the financial net revenue calculation.

Instead, actual refund amounts from `fact_returns.refund_amount` are used as the financial deduction.

---

## Final KPI Definition

### Gross Revenue

```text
Gross Revenue = Total order value excluding cancelled orders
```

Cancelled orders are not treated as recognized gross revenue.

### Financial Net Revenue

```text
Financial Net Revenue = Gross Revenue - Actual Refund Amount
```

This is the main net revenue KPI used for financial analysis.

### Deduction Rate

```text
Deduction Rate = Actual Refund Amount / Gross Revenue
```

This shows the share of gross revenue lost through actual recorded refunds.

---

## Treatment of Order Statuses

Returned and refunded order statuses will still be analyzed, but separately from the financial net revenue KPI.

They are treated as operational indicators.

### Operational Status Impact

```text
Returned Order Value = Gross order value affected by Returned status
Refunded Order Value = Gross order value affected by Refunded status
Cancelled Order Value = Order value excluded due to Cancelled status
```

This helps answer questions such as:

* How much order value is affected by return-related statuses?
* How large is the gap between affected order value and actual refund amount?
* Are returned/refunded statuses causing financial loss, operational friction, or both?

---

## Why This Decision Was Made

The decision was made because the validation showed that status-based deduction and refund-amount-based deduction produce materially different results.

Using full returned/refunded order value as financial deduction would reduce net revenue too aggressively.

The difference between the two methods is large enough to affect business conclusions.

Therefore, the model separates:

```text
Financial Net Revenue
```

from:

```text
Operational Status Impact
```

This avoids mixing accounting logic with operational order-status logic.

---

## Business Rule Assumption

The current financial net revenue calculation assumes:

```text
1. Cancelled orders are excluded from gross revenue.
2. Actual refund amount is the best available monetary deduction field.
3. Returned and Refunded statuses are operational indicators, not full financial deductions.
```

This assumption should be confirmed with stakeholders before the KPI is treated as final business logic.

---

## Stakeholder Questions

The following questions should be clarified with a business stakeholder or data owner:

1. Are cancelled orders always excluded from recognized gross revenue?
2. Is `fact_returns.refund_amount` the authoritative source for actual refund value?
3. Can returned orders receive partial refunds?
4. Can refunded orders represent partial refunds?
5. Do `Returned` and `Refunded` statuses describe operational states, financial states, or both?
6. Should returned/refunded order value be reported as affected order value rather than deducted revenue?
7. Are exchanges or store credits included in the dataset?
8. Should financial net revenue be based on refund amount, order status, or another accounting field?

---

## Severity

High

## Reason

This decision affects core financial KPIs:

* gross revenue
* net revenue
* refund deduction
* deduction rate
* year-over-year revenue trend
* interpretation of returned/refunded order impact

Using the wrong deduction logic could significantly understate or overstate net revenue.

---

## Documentation Decision

This issue is documented as a business-rule and KPI-definition decision, not as a simple data-cleaning issue.

The final documentation should clearly distinguish between:

```text
Financial Net Revenue
```

and:

```text
Operational Status Impact
```

until the business logic is confirmed by stakeholders.

---

## Recommended Chart Naming

Use:

```text
Financial Net Revenue Trend
```

for charts based on actual refund amounts.

Use:

```text
Order Status Impact on Gross Revenue
```

for charts showing cancelled, returned, and refunded order values.

Avoid calling the status-based result "net revenue" unless the business confirms that full returned/refunded order value should be deducted.