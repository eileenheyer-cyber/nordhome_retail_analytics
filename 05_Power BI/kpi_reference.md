# NordHome Dashboard — KPI Reference

The KPI cards actually shown on each dashboard page — what each one means and how to read it, without the DAX. For the formula and the *why* behind each one, see [dax_measures.md](dax_measures.md); this file skips the building-block ("Foundations") and formatting-only measures on purpose, since those never appear as a KPI card themselves.

---

## Executive Overview

| KPI | Meaning | How to read it |
|---|---|---|
| Net Revenue (H1) | Net revenue restricted to Jan–Jun of whichever year is in context | Any figure labelled H1 is directly comparable year over year; figures without that label are not |
| H2 Revenue Forecast | Projected revenue for months that haven't happened yet | A flat run-rate estimate, not a modelled forecast with a confidence interval — label it as an estimate wherever it appears |
| Gross Profit | Net revenue less cost of goods | Already net of refunds — costing off gross revenue would overstate this |
| Gross Margin | Gross profit as a share of revenue | Denominator is gross, not net — mixing a net numerator with a net denominator would double-count the refund effect |
| Completed Orders | Orders with status exactly "Completed" | Fulfilment reporting, not the AOV denominator — a smaller, stricter count than Non-Cancelled Orders |
| Net AOV | Net revenue ÷ non-cancelled orders | The one number that ties revenue, order count, and customer count together (see the decomposition identity in dax_measures.md) |
| Lost Revenue % | Cancelled + returned + refunded value, as a share of Gross Order Value | The headline loss figure — all three components share one denominator (GOV) so they sum cleanly |
| Cancelled / Returned / Refunded % of GOV | Each loss type's own share of Gross Order Value | Read side by side — same base for all three, so the ranking between them is meaningful |

## Sales & Product Performance

| KPI | Meaning | How to read it |
|---|---|---|
| Sell-Through Rate (H1) | H1 units sold ÷ units currently in stock | Directional only — high means fast-moving, low means overstock risk. Not a true inventory turn rate |
| Return Rate | Returned value as a share of revenue | Value-based, not unit-based — comparable to the other loss-rate KPIs |
| Discount Impact (list value based) | Revenue conceded through discounting, vs. list value | Captures the full gap between what could have been charged and what was |
| Discontinued Product Revenue Exposure | Share of revenue from products flagged discontinued | A risk measure — revenue that disappears once those products are actually withdrawn |
| 2023 Launch Cohort Revenue Share | Share of revenue from products launched in 2023 | Read together with the KPI above — high discontinued exposure plus a thin new-launch cohort is a replacement problem |

> Product, subcategory, channel, and brand revenue are uniformly random in this dataset — no ranking or concentration KPI (top-seller, ABC/Pareto, brand performance) was built here on purpose. See `decisions_log.md`.

## Customer Analysis

| KPI | Meaning | How to read it |
|---|---|---|
| Total Customers | Distinct customers with at least one order, any status | Includes customers whose only order was cancelled — `Active Customers` (Foundations) is the stricter version |
| Repeat Customers | Customers with more than one non-cancelled order | Period-scoped: in a six-month view this means "twice in those six months," not "ever bought twice" |
| Repeat Purchase Rate | Repeat Customers ÷ Total Customers | Same population in numerator and denominator |
| Net Revenue per Customer | Net revenue ÷ Total Customers | A per-customer value proxy — deliberately not called lifetime value, since there's no real customer lifecycle in this dataset |
| New Customers Registered | Customers whose registration date falls in the period | Counts by registration date, not first-order date — will not match `New Customers` (Foundations) |
| Churn Rate (to date) | Share of the customer base silent for six months or more | A snapshot ("how many are lapsed right now"), not a monthly flow |
| Customers / Revenue per Customer by Order Frequency | Customer counts and value by purchase-frequency band (1, 2, 3, 4, 5+ orders) | Revenue per customer is the one that shows real differentiation here — it rises ~10× from the lowest to highest band, while AOV across the same bands is flat |

> Loyalty membership (`loyalty_member`) is randomly assigned in this dataset — no loyalty-vs-non-loyalty comparison KPI was built here on purpose. Order Frequency Band is the split that actually carries signal. See `decisions_log.md`.

## Marketing Analysis

| KPI | Meaning | How to read it |
|---|---|---|
| Customers Reached | Distinct customers exposed to at least one touchpoint | Reach, not volume |
| Click Through Rate (CTR) | Share of touchpoints clicked | — |
| Conversion Rate | Share of touchpoints that converted | Includes conversions with no preceding click — a tighter click-to-conversion measure exists separately |
| Revenue from Converted Customers (Post-Conversion) | Revenue from customers with a converting touchpoint, within 90 days of their first conversion | Read as *90-day post-conversion customer value*, not *revenue this campaign caused* — touchpoints and orders share no order ID, so this isn't true attribution |
| Marketing ROI | (Post-conversion revenue − campaign cost) ÷ campaign cost | 100% = break-even before overhead. Blank below 30 conversions, since a single customer can swing the ratio by hundreds of percent at that volume. Campaign cost is an estimated placeholder, not actual spend — directional only |

---

*Three measures are easy to confuse across this reference and `dax_measures.md`: `Churned Customers` (flow) vs. `Churned Customers (to date)` (stock); `New Customers` (first order) vs. `New Customers Registered` (registration date); `Total Customers` vs. `Active Customers` vs. `Customer Base` (all orders / non-cancelled only / everyone ever). See "Reading these together" in `dax_measures.md` for the full table.*
