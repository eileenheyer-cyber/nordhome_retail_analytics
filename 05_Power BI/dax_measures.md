# NordHome Dashboard — DAX Measures Reference

Sourced from the current PBIP-based rebuild of the dashboard (25 tables, 16 relationships, 143 measures in a dedicated `_measures` table, organised by display folder). This is the final, authoritative measures reference for this project — earlier drafts (`power_bi_modelling_decisions.md`, `dashboard_design.md`) are superseded.

Each entry gives what the measure does, its DAX, and *why* it's written that way. Foundations first, then every measure driving a KPI card, page by page. For a lighter, business-facing list of just the KPI cards (no DAX), see [kpi_reference.md](kpi_reference.md).

---

## Foundations — the revenue chain

Revenue passes through four stages, each answering a different question. Keeping them as separate measures rather than one "revenue" number is what makes leakage visible.

**Gross Order Value (GOV)** — everything ordered, regardless of status. Answers *what was demanded*.
```dax
SUM(fact_order_items[line_total])
```
*Why:* no status filter at all. This is the only measure that counts cancelled orders, which makes it the correct denominator for loss percentages — cancelled value has to be in the base for "% cancelled" to mean anything.

**Gross Sales Revenue** — orders that were not cancelled. Answers *what we agreed to fulfil*.
```dax
CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] <> "Cancelled")
```
*Why:* `<> "Cancelled"` rather than listing the statuses we want. New statuses added upstream are included automatically instead of silently dropping out.

**Refund Revenue** — cash actually refunded.
```dax
SUM(fact_returns[refund_amount])
```
*Why:* sourced from `fact_returns`, not from order status. A returned order and the amount refunded on it are different numbers, and only this table holds the second one.

**Net Revenue** — revenue after refunds. Answers *what we kept*.
```dax
[Gross Sales Revenue] - [Refund Revenue]
```
*Why:* keeps returned line value and subtracts only the actual refund, rather than writing off the whole line. That is the difference between this and `Kept Order Value`, which is status-based — the two differ by roughly 7% at subcategory level.

**Lost Revenue** — order value that never converted.
```dax
CALCULATE(
    SUM(fact_order_items[line_total]),
    fact_order_items[order_status] IN {"Cancelled","Returned","Refunded"}
)
```
*Why:* one filter over three **mutually exclusive** statuses instead of adding three measures together. Double counting is structurally impossible, so the components always sum to the total with no residual.

---

## Foundations — the decomposition identity

The model rests on one identity, and it is what makes the revenue driver waterfall reconcile exactly:

**Net Revenue = Active Customers × Orders per Customer × Net AOV**

**Non-Cancelled Orders** — distinct orders excluding cancellations.
```dax
CALCULATE(DISTINCTCOUNT(fact_order_items[order_id]), fact_order_items[order_status] <> "Cancelled")
```
*Why:* counts distinct `order_id`, not rows — the fact table is at line grain, so `COUNTROWS` would count items and inflate every per-order metric. Renamed from "Completed Orders", which never filtered to Completed and was actively misleading.

**Active Customers** — distinct customers with at least one non-cancelled order.
```dax
CALCULATE(DISTINCTCOUNT(fact_order_items[customer_key]), fact_order_items[order_status] <> "Cancelled")
```
*Why:* same `<> "Cancelled"` basis as the orders and revenue measures. A customer whose only order was cancelled never transacted, so counting them would break the identity above.

**Orders per Customer** — purchase frequency.
```dax
DIVIDE([Non-Cancelled Orders], [Active Customers])
```
*Why:* `DIVIDE` rather than `/` — returns blank instead of an error when a slicer produces an empty customer set.

**Net AOV** — average order value, net of refunds.
```dax
DIVIDE([Net Revenue], [Non-Cancelled Orders])
```
*Why:* the denominator is `Non-Cancelled Orders`, not `Completed Orders`. The numerator covers all non-cancelled revenue, so the denominator has to cover the same population or the average is computed over mismatched bases.

All four share one filter basis. That consistency is the whole point — mismatched denominators are what silently break a decomposition.

---

## Foundations — customer lifecycle

A note on the date anchor, since this whole group depends on it: orders stop on **30 June 2024** while `dim_date` runs to 31 December 2024. Every measure below that involves elapsed time is anchored to `[As Of Date]` — the visible period end, capped at the last date with actual orders. Without that cap, the six empty months count as time passing and every active customer is wrongly declared churned.

**Customer Base** — every customer who has ever ordered, up to the reporting cut-off. The denominator for retention questions.
```dax
VAR AsOf = [As Of Date]
RETURN
    CALCULATE (
        DISTINCTCOUNT ( fact_order_items[customer_key] ),
        ALL ( dim_date ),
        dim_date[full_date] <= AsOf
    )
```
*Why:* deliberately ignores the **start** of the date filter — slicing to March doesn't reduce it to March's customers, it still counts everyone acquired up to that point. That's what makes it a *base* rather than a period count, and the difference between this and `Total Customers`. Splits exactly into Retained + Churned (to date), so the two can be stacked in one bar.

**Retained Customers (to date)** — customers who ordered within the six months ending at the cut-off.
```dax
VAR AsOf = [As Of Date]
RETURN
    CALCULATE (
        DISTINCTCOUNT ( fact_order_items[customer_key] ),
        ALL ( dim_date ),
        dim_date[full_date] > EDATE ( AsOf, -6 ),
        dim_date[full_date] <= AsOf
    )
```
*Why:* six months of silence means gone. The window travels with the measure rather than coming from the page filter, so it stays a true six months whatever the slicer says. *Where it stops being reliable:* six months is a convention, not a derived threshold — defensible for a home-goods retailer bought twice a year, but arguable. If the business defines lapse differently, `EDATE(AsOf, -6)` is the one number to change.

**Churned Customers (to date)** — customers in the base with no order for six months or more. A **stock**, not a flow — "how many customers are currently lapsed," not "how many lapsed this month."
```dax
[Customer Base] - [Retained Customers (to date)]
```
*Why:* churn as the *complement* of retention rather than a separate calculation. The two cannot disagree or overlap, and they sum exactly to the base — what makes the stacked bar honest.

**Churned Customers** — the flow counterpart: how many customers *crossed into* churn during the visible period.
```dax
VAR PeriodStart = MIN(dim_date[full_date])
VAR PeriodEnd = MAX(dim_date[full_date])
RETURN
CALCULATE(
    SUMX(
        VALUES(fact_order_items[customer_key]),
        VAR LastOrderDate =
            CALCULATE(MAXX(fact_order_items, RELATED(dim_date[full_date])), ALL(dim_date))
        VAR ChurnDate = EDATE(LastOrderDate, 6)
        RETURN IF(ChurnDate >= PeriodStart && ChurnDate <= PeriodEnd, 1, 0)
    ),
    ALL(dim_date)
)
```
*Why:* each customer's churn date is their last order plus six months, counted in the month that date falls into. Period boundaries are captured *before* `ALL(dim_date)` clears the filter — otherwise the measure would lose the very window it's testing against. *Where it stops being reliable:* a customer can only churn once, in one month — if they order again afterwards they were never really churned, but this measure will still have counted them. Read the trend, not any single month. **Do not confuse with `Churned Customers (to date)`** — one is a flow, one is a stock; they will not tie.

**New Customers** — customers whose very first order *ever* falls inside the visible period.
```dax
VAR PeriodStart = MIN(dim_date[full_date])
VAR PeriodEnd = MAX(dim_date[full_date])
RETURN
SUMX(
    VALUES(fact_order_items[customer_key]),
    VAR FirstOrderDate = CALCULATE(MINX(fact_order_items, RELATED(dim_date[full_date])), ALL(dim_date))
    RETURN IF(FirstOrderDate >= PeriodStart && FirstOrderDate <= PeriodEnd, 1, 0)
)
```
*Why:* checked against a customer's whole history, not first order in the visible window — someone active every month is new exactly once. **Not the same as `New Customers Registered`**, which counts by registration date through an inactive relationship; a customer can register in one month and first order in another, and both measures are correct.

**Repeat Customers** — see Customer Analysis KPI cards below. Period-scoped: in a six-month view this means "ordered twice in those six months," not "ever bought twice."

**Customers by Order Frequency** — how many customers sit in each purchase-frequency band (1, 2, 3, 4, 5+ orders). Built as a virtual customer-by-order-count table at query time rather than a fixed calculated column, so the bands respond to the year slicer instead of being frozen at refresh. *Where it stops being reliable:* the bands are **period-scoped** — the same page reads 66% single-order for H1 2024 and 59% all-time. Always state the period alongside the number.

**Revenue per Customer by Order Frequency** — average net revenue per customer within each frequency band.
*Why:* iterates `VALUES(dim_customer[customer_key])`, not the fact table's customer column. Both `fact_order_items` and `fact_returns` join `dim_customer`, so filtering there reaches **both** and refunds are attributed per customer — going via the fact column would miss `fact_returns`, and every band would silently carry the full unfiltered refund total. *Why this and not AOV:* AOV is flat across the bands (€368–434, no direction); revenue per customer rises about tenfold from the lowest band to the highest — that's the real finding.

---

## Executive Overview — KPI cards

**Net Revenue (H1)** — net revenue restricted to Jan–Jun of whichever year is in context.
```dax
CALCULATE([Net Revenue], dim_date[month_number] <= 6)
```
*Why:* `dim_date` holds all 12 months of 2024 but orders stop on 30 June. An unguarded year-over-year compares six months of 2024 against twelve of 2023 and overstates the decline by roughly 65×. `TOTALYTD` has the same flaw here, which is why the guard is explicit and applied to **both** sides of every comparison. *How to read it:* any figure labelled H1 on this report is directly comparable year to year. Figures without that label are not.

**H2 Revenue Forecast** — projected revenue for the months that haven't happened yet, returning **blank** for any month that already has actuals so the forecast line can never overwrite one. Full DAX and design rationale in [decisions_log.md](decisions_log.md) ("H2 Revenue Forecast — flat run-rate, not seasonal"). *Where it stops being reliable:* it assumes H1's growth rate continues and last year's monthly shape repeats — a run-rate, not a forecast with a confidence interval. Label it as such wherever it appears.

**Gross Profit** — net revenue less cost of goods.
```dax
[Net Revenue] - [COGS(List Basis)]
```
*Why:* built on Net Revenue, so refunds are already removed before margin is calculated. Costing off gross would overstate profit by the refund amount.

**Gross Margin** — profit as a share of revenue.
```dax
DIVIDE([Gross Profit], [Gross Sales Revenue])
```
*Why:* the denominator is gross, not net. Margin answers "how much of what we sold did we keep", and mixing a net numerator with a net denominator would double-count the refund effect.

**Completed Orders** — orders with status exactly `"Completed"`.
```dax
CALCULATE(DISTINCTCOUNT(fact_order_items[order_id]), fact_order_items[order_status] = "Completed")
```
*Why:* deliberately **not** the AOV denominator. This is fulfilment reporting — orders that closed. `Non-Cancelled Orders` is the revenue-side count and also includes Shipped, Processing, Returned and Refunded. The two are near enough in size to look interchangeable and are not.

**Net AOV** — see the decomposition section above.

**Lost Revenue %, Cancelled/Returned/Refunded % of GOV** — see [decisions_log.md](decisions_log.md) ("Revenue-lost denominator" decision) for the full reasoning behind why GOV is the shared denominator for every loss-rate measure, and why `Refunded` is sourced from `order_status`, not `fact_returns`.

---

## Sales & Product Performance — KPI cards

**Sell-Through Rate (H1)** — H1 units sold against units currently in stock.
```dax
DIVIDE(
    CALCULATE([Gross Unit Sold], dim_date[month_number] <= 6),
    SUM(dim_product[Inventory])
)
```
*Why:* mixes a period flow (units sold) with a point-in-time stock level, because `dim_product` carries only current inventory with no history. *How to read it:* directionally — high means fast-moving, low means overstock risk. *Where it stops being reliable:* it is **not** a true inventory turn rate — that needs average stock over the period, which this data cannot provide.

**Return Rate** — returned value as a share of revenue.
```dax
DIVIDE([Returned Order Value], [Gross Sales Revenue])
```
*Why:* value-based, not unit-based, and the returned value sits in both numerator and denominator. That matches how the loss percentages elsewhere are constructed, so the two can be read side by side.

**Discount Impact (list value based)** — revenue conceded through discounting.
```dax
[List Value (Pre - Discount)] - [Gross Sales Revenue]
```
*Why:* measured against list value rather than by summing the discount column, so it captures the full gap between what could have been charged and what was.

**Discontinued Product Revenue Exposure** — share of revenue from products flagged discontinued.
```dax
DIVIDE(
    CALCULATE([Net Revenue], dim_product[discontinued_flag] = TRUE),
    [Net Revenue]
)
```
*Why:* expressed as a share, not an absolute. The question is how exposed the business is, and a euro figure would move with overall volume rather than with the exposure itself. *How to read it:* a risk measure — revenue that will disappear once those products are actually withdrawn.

**2023 Launch Cohort Revenue Share** — share of revenue from the newest products.
```dax
DIVIDE(
    CALCULATE([Net Revenue], FILTER(dim_product, YEAR(dim_product[launch_date]) = 2023)),
    [Net Revenue]
)
```
*Why:* a pipeline health check — paired with the measure above it shows how much revenue leans on products on the way out versus products just arriving. *How to read it:* a business with high discontinued-product exposure and a thin new-launch cohort has a replacement problem, not just two unrelated stats.

> **Do not build:** ABC/Pareto classification, top-seller concentration, long-tail, SKU rationalisation, channel-preference, or brand-performance analysis on this dataset. Product, subcategory, channel, and brand revenue are uniformly random by construction — see [decisions_log.md](decisions_log.md) ("Dataset characteristics") for the full evidence.

---

## Customer Analysis — KPI cards

**Total Customers** — distinct customers with at least one order.
```dax
DISTINCTCOUNT(fact_order_items[customer_key])
```
*Why:* no status filter, so it includes customers whose only order was cancelled, and the `-1` "Unknown Customer" placeholder unless one is applied. `Active Customers` is the stricter alternative used in the decomposition.

**Repeat Customers** — customers with more than one non-cancelled order.
```dax
SUMX(
    VALUES(fact_order_items[customer_key]),
    VAR OrdersForCustomer =
        CALCULATE(
            DISTINCTCOUNT(fact_order_items[order_id]),
            fact_order_items[order_status] <> "Cancelled"
        )
    RETURN IF(OrdersForCustomer > 1, 1, 0)
)
```
*Why:* iterates per customer rather than using a calculated column, so it respects the date slicer instead of being fixed at refresh. Cancelled orders are excluded — a cancelled order was never fulfilled and isn't a genuine repeat purchase.

**Repeat Purchase Rate** — share of customers who came back.
```dax
DIVIDE([Repeat Customers], [Total Customers])
```
*Why:* denominator is `Total Customers`, matching the numerator's population.

**Net Revenue per Customer** — average value per customer.
```dax
DIVIDE([Net Revenue], [Total Customers])
```
*Why:* a per-customer value proxy, deliberately not called lifetime value — there is no lifecycle in this data to compute one from (see [decisions_log.md](decisions_log.md), "order dates are uniformly random").

**New Customers Registered** — customers whose registration date falls in the current period.
```dax
CALCULATE(
    DISTINCTCOUNT(dim_customer[customer_id]),
    USERELATIONSHIP(dim_customer[registration_date], dim_date[full_date])
)
```
*Why:* activates an inactive relationship so this one measure counts by **registration** date while everything else on the page counts by **order** date. Two date relationships cannot both be active, so the alternative would be a second date table.

**Churn Rate (to date)** — share of the base silent for six months or more.
```dax
DIVIDE([Churned Customers (to date)], [Customer Base])
```
*Why:* anchored to `[As Of Date]` — the last date that actually has orders, not the end of the calendar. Without that anchor the six empty months at the tail of `dim_date` count as elapsed time and every active customer is wrongly flagged as churned.

**Customers by Order Frequency** and **Revenue per Customer by Order Frequency** — see [Foundations — customer lifecycle](#foundations--customer-lifecycle) above. The second is the one that actually shows customer-value differentiation on this dataset (revenue rises ~10× from the lowest to highest frequency band); AOV across the same bands is flat (€368–434) and would draw a trend line where none exists.

> **Do not build:** loyalty member vs. non-member comparison visuals. `loyalty_member` is randomly assigned — see [decisions_log.md](decisions_log.md) for the full evidence and what to do instead (Order Frequency Band is the split that carries real signal).

---

## Marketing Analysis — KPI cards

**Customers Reached** — distinct customers exposed to at least one touchpoint.
```dax
DISTINCTCOUNT(fact_marketing_touchpoints[customer_key])
```
*Why:* reach, not volume. Paired with `Touchpoints per Customer` it separates how many people were reached from how hard each was hit.

**Click Through Rate (CTR)** — share of touchpoints clicked.
```dax
DIVIDE([Total Clicks], [Total Touchpoints])
```

**Conversion Rate** — share of touchpoints that converted.
```dax
DIVIDE([Total Conversions], [Total Touchpoints])
```
*Why:* both divide into the same touchpoint base, so the funnel stages are comparable. Note this includes conversions with no preceding click — `Click-to-Conversion Rate` is the tighter measure that divides into clicks.

**Revenue from Converted Customers (Post-Conversion)** — revenue from customers with a converting touchpoint, within 90 days of their first conversion.
*Why:* the 90-day cap matches standard ad-platform attribution windows (Google Ads 30–90 days, Meta 7–28) and stops marketing being credited with a customer's ordinary repeat shopping years later — the uncapped version implied roughly 36× ROI, which was the clue it was measuring the wrong thing. It bridges through `dim_customer[customer_key]` rather than the fact table directly, because filtering `fact_order_items` does not propagate to `fact_returns`; the two facts share only the customer dimension, and going direct left refunds completely unfiltered. *Where it stops being reliable:* this is **not** true attribution — touchpoints and orders share no order ID, so nothing links a specific order to a specific campaign. Read it as *90-day post-conversion customer value*, not *revenue this campaign caused*. Also the heaviest DAX in the model (row-by-row iteration with a nested date lookup) — fine at this size, worth revisiting if the data grows substantially.

**Marketing ROI** — post-conversion revenue against campaign cost.
```dax
IF(
    [Total Conversions] >= 30,
    DIVIDE(
        [Revenue from Converted Customers (Post-Conversion)] - [Total Campaign Cost],
        [Total Campaign Cost]
    )
)
```
*Why:* blanked below 30 conversions. Under that threshold one customer's ordinary purchase swings the ratio by hundreds of percent — a campaign with 23 conversions showed 4,560% ROI, traced to 2 of its 10 converting customers accounting for 53% of attributed revenue. Showing nothing is more honest than showing a number that is mostly noise. *How to read it:* 100% means revenue matched cost — break-even before overhead; 200% means three times the cost came back. *Where it stops being reliable:* campaign cost is an estimated placeholder, not actual spend, and it sits once per campaign rather than per touchpoint or per date — slicing by date alone will not reduce the cost total. Directional only.

---

## Reading these together

Three pairs are easy to confuse, and each pair is correct — they're deliberately answering different questions, not disagreeing:

| | |
|---|---|
| `Churned Customers` vs `Churned Customers (to date)` | flow vs. stock — they will not tie |
| `New Customers` vs `New Customers Registered` | first order vs. registration date |
| `Total Customers` vs `Active Customers` vs `Customer Base` | all orders / non-cancelled only / everyone ever |

One caution that applies throughout: frequency bands, repeat rate, and churn measures are all **period-scoped** unless the name says *(to date)*. Quoting one without its period is the most likely way to be wrong with these numbers.

---

## Helper measures

Measures suffixed `... Display` and `... Color` — for example `Net AOV YoY Display` and `Gross Margin YoY Color` — carry no analysis. One returns a formatted string with an arrow, the other a hex colour for conditional formatting, so each KPI card can show a value, a trend and a colour. They are split out rather than embedded because Power BI needs a separate measure per formatting slot.

**Disconnected helper tables** — `Funnel Stage`, `Loss Reason`, `Revenue Driver`, `Order Frequency Band`, `Metric`, `Growth By`, and others carry no relationships; they exist to give a category axis to measures that switch on `SELECTEDVALUE`, letting one measure drive a whole chart.

---

*Excluded from this file: the 5 `Dax Practice` scratch measures and 2 abandoned `Funnel Middle`/`Funnel Right` measures — removed from the model, kept only in [decisions_log.md](decisions_log.md) as a record of why.*
