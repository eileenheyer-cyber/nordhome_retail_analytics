# Power BI Dashboard Design — NordHome Retail

Status: **draft, in progress.** Started 2026-08-02. Built page by page.

This file is the standalone design reference for the Power BI report — business questions, DAX measures, and layout for every page.

---

## Purpose of this document

One report, four pages, one shared design system. This file records, per page:

1. The business question(s) the page must answer
2. The DAX measures it needs
3. A layout suggestion

Plus report-level conventions that apply across all pages, so pages don't quietly drift apart from each other.

---

## Global design standards

Applies to every page unless a page explicitly overrides it.

**KPI cards**
- Size: ~190–210px wide × 100–120px tall, landscape not square
- Callout (big number) font: 28–36pt, filling ~60–70% of card height
- Label font: 10–12pt
- Delta/comparison font: 9–10pt, smaller than the label

**Color**
- Accent color: orange `#F2632D`, used only for the metric being highlighted on a given chart — never repurposed as "just another category color"
- Same accent meaning across every page: orange = the thing the viewer's eye should land on first

**Typography**
- Page title: 24pt bold (matches `CLAUDE.md` chart title convention)
- Page subtitle stating that page's Big Idea: 13–14pt
- KPI card numbers may exceed the page title size (they're the single most important number on the card) but card labels stay below subtitle size

**Number formatting**
- Currency abbreviated (€22.7M, not €22,684,205) — matches "no unnecessary precision" rule
- Consistent decimal precision for comparable metrics across all pages (e.g. all % metrics to 1 decimal)

**Filters**
- Default date filter: Jan–Jun comparable, applied consistently across pages, stated visibly on each page (not just Executive Overview) since 2024 is a half-year only in `dim_date`
- **Exception:** the Returns & Revenue Risk page's central chart (Returned/Refunded Order Value vs. Refund Revenue) uses the full 2021–2024 range, not the Jan–Jun comparable filter — the underlying €4.63M/€914K finding was validated full-dataset. State this explicitly in that chart's subtitle so it's never assumed to match the Jan–Jun default.
- Product/category-level visuals must exclude `ghost_product_flag = TRUE` — ghost rows (`product_key = -1`) have no reliable attributes and will distort rankings

**Navigation**
- Same page-tab style and position across all four pages

---

## Report-level modelling prerequisite

`dim_date` must be marked as a **Date Table** in Power BI (Modeling → Mark as Date Table, using `full_date`) before building any time-intelligence measure (`SAMEPERIODLASTYEAR`, `DATEADD`, `TOTALYTD`, rolling windows). Do this once, first, before Executive Overview measures are built — several measures below depend on it silently misbehaving otherwise.

---

## Revenue-metric consistency rule

**Decision:** Use **Net Revenue** as the default revenue metric across all pages (Executive Overview, Sales & Product Performance, Customer Behavior), except on the Returns & Revenue Risk page, which needs the gross/refund breakdown by definition.

**Reason:** Without a stated default, different pages could end up quietly built on different revenue tiers (GOV vs. Gross Sales Revenue vs. Net Revenue), and a viewer comparing numbers across pages would see mismatches with no visible explanation.

---

## Page 1: Executive Overview

### Business question

**Big question:** Is NordHome Retail growing, and is that growth trustworthy?

**Sub-questions:**
1. How much revenue are we generating, and is it going up or down?
2. Is growth coming from more orders or bigger baskets?
3. How much of our reported revenue is at risk from returns?
4. Is performance stable month to month, or hiding volatility?
5. Are we profitable after cost, not just top-line?
6. Where is this trending — what does the near-term outlook look like?

### DAX measures needed

**KPI cards**

```dax
Net Revenue = [Gross Sales Revenue] - [Refund Revenue]

YoY Growth % (Comparable) =
VAR CurrentYTD = [Net Revenue Comparable YTD]
VAR PriorYTD = CALCULATE([Net Revenue Comparable YTD], SAMEPERIODLASTYEAR(dim_date[full_date]))
RETURN DIVIDE(CurrentYTD - PriorYTD, PriorYTD)

Net AOV = DIVIDE([Net Revenue], [Completed Orders])

Completed Orders =
CALCULATE(DISTINCTCOUNT(fact_order_items[order_id]), fact_order_items[order_status] <> "Cancelled")

Return Rate = DIVIDE([Refund Revenue], [Gross Sales Revenue])

Gross Margin % = DIVIDE([Gross Profit], [Net Revenue])
```

**Secondary/tooltip metrics** — shown as supporting context on existing cards, not new cards of their own:

```dax
Net Revenue MoM % =
VAR PM =
    CALCULATE(
        [Net Revenue],
        DATEADD(dim_date[full_date], -1, MONTH),
        REMOVEFILTERS(dim_date[year]) /* without this, a Year slicer blocks Jan's prior-month lookup */
    )
RETURN DIVIDE([Net Revenue] - PM, PM)

Net AOV YoY % (Comparable) =
VAR CurrentAOV = CALCULATE([Net AOV], dim_date[month_number] <= 6)
VAR PriorAOV = CALCULATE([Net AOV], dim_date[month_number] <= 6, SAMEPERIODLASTYEAR(dim_date[full_date]))
RETURN DIVIDE(CurrentAOV - PriorAOV, PriorAOV)
```

`Net Revenue MoM %` goes as tooltip/secondary text on the **YoY Growth %** card — it's the early-warning signal for a problem YoY is too slow to catch. `Net AOV YoY % (Comparable)` goes as tooltip/secondary text on the **Net AOV** card — it answers sub-question 2 (orders vs. bigger baskets) directly, more precisely than reading two separate cards side by side.

**Trend chart**

```dax
Net Revenue Rolling 12M =
CALCULATE([Net Revenue], DATESINPERIOD(dim_date[full_date], LASTDATE(dim_date[full_date]), -12, MONTH))
```

**H1 comparison strip — no dedicated measures needed**

Built as a clustered bar chart: `Year` on the axis, a visual-level filter `Quarter IN {1, 2}`, and the base measures already defined elsewhere on this page — `Net Revenue`, `Return Rate`, `Discount Rate %` (the last one defined on Sales & Product Performance, reused here). This shows H1 2024 vs. H1 2023 as two bars per metric with no hardcoded-year measures, and keeps working unchanged if 2025 data is ever added — no maintenance needed later.

`H1 YoY Growth %` is deliberately *not* built as a separate measure: `YoY Growth % (Comparable)` (defined above) already computes Jan–Jun vs. Jan–Jun generically via `SAMEPERIODLASTYEAR`. Evaluated in a 2024 filter context, it returns the same number a hardcoded H1-2024-vs-2023 measure would — building both would be a true duplicate, not a design choice.

**Hidden dependencies** (not displayed, but feed the measures above — build first)

```dax
Gross Sales Revenue =
CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] <> "Cancelled")

Refund Revenue = SUM(fact_returns[refund_amount])

Net Revenue Comparable YTD = CALCULATE([Net Revenue], dim_date[month_number] <= 6)

COGS =
CALCULATE(
    SUMX(fact_order_items, fact_order_items[quantity] * RELATED(dim_product[unit_cost])),
    fact_order_items[order_status] <> "Cancelled",
    fact_order_items[ghost_product_flag] = FALSE
)

Gross Profit = [Net Revenue] - [COGS]
```

**H2 2024 Forecast** — not a DAX measure, a chart-level Power BI feature (Analytics pane), extending the Rolling 12M trend chart above.

- X-axis: `dim_date[full_date]` (must be the continuous date field, not `year_month` — the Analytics-pane forecast requires it), drilled to Month granularity.
- Y-axis: `[Net Revenue]`.
- Analytics pane → **Forecast** → Forecast length = 6 (months) → Confidence interval 95%.
- Toggle or shaded projection on the *same* trend chart, not a separate visual — this is an extension of "where are we trending," not a new topic.

**Limitation — footnote on the chart, not skipped:** only 42 months of history, and it's synthetic, generated data. Power BI's forecast (exponential smoothing) will detect *some* seasonal pattern whether or not a real one exists. Present as an illustrative projection, not a confident business forecast.

### Layout

```
┌──────────────────────────────────────────────────────────┐
│  NordHome Retail — Executive Overview                     │
│  Jan–Jun comparable, all years   [data-as-of note]        │
├──────┬──────┬──────┬──────┬──────┬──────┬─────────────────┤
│ Net  │ YoY  │ Net  │ Comp-│ Ret. │ Gross│                 │
│ Rev  │Growth│ AOV  │leted │ Rate │Margin│                 │
│      │ %*   │  *   │Orders│      │  %   │                 │
├──────┴──────┴──────┴──────┴──────┴──────┴─────────────────┤
│ * YoY card tooltip: MoM %  |  Net AOV card tooltip: AOV YoY │
├──────────────────────────────────────────────────────────┤
│                                                             │
│   Net Revenue — Rolling 12M trend + H2 2024 Forecast        │
│   (line chart, full width, orange = actuals,                │
│    shaded band = forecast + 95% CI, footnote on synthetic-  │
│    data limitation)                                         │
│                                                             │
├───────────────────────────┬─────────────────────────────────┤
│ H1 2024 vs H1 2023           │  Note: flat, -1.3%, footnote   │
│ Net Rev / Return Rate /      │  on the €3.7M return/refund    │
│ Discount Rate (clustered     │  gap → "see Returns page"      │
│ bars, Year axis, Quarter     │                                 │
│ IN {1,2} filter — no         │                                 │
│ dedicated measures)          │                                 │
└───────────────────────────┴─────────────────────────────────┘
```

Six KPI cards carry the headline numbers, two with a secondary metric on hover (MoM % on YoY, AOV YoY on Net AOV) rather than adding two more cards and crowding the row. One dominant rolling trend chart — now extended with the forecast band — carries the Big Idea. Bottom strip gives the H1 comparison via a filtered chart, not hardcoded measures, and signposts to the Returns page rather than explaining the refund gap here.

---

## Page 2: Sales & Product Performance

### Business question

**Big question:** What's driving revenue, and what's dragging on it?

**Sub-questions:**
1. Which product categories/subcategories generate the most revenue?
2. Which individual products are the strongest and weakest performers?
3. Which sales channel and shipping method perform best?
4. How much revenue are we giving away through discounting, and where is it worst?
5. Is this picture reliable, or distorted by data quality issues?

### DAX measures needed

**Revenue by Category / Top-Bottom Products / Revenue by Channel** — no dedicated measure. All three reuse `Net Revenue` (defined on the Executive Overview page), sliced by `dim_product[category]`, `dim_product[product_name]`, or `fact_order_items[sales_channel]` respectively. Category and product slices must add a visual-level filter `ghost_product_flag = FALSE`; channel needs no filter since it's a fact-level attribute, not a dimension join.

**Discount Rate % by Channel**

```dax
Discount Rate % = DIVIDE([Discount Impact], [List Value (Pre-Discount)])
```

Sliced by `fact_order_items[sales_channel]` — both columns live directly on the fact table, no join needed.

**Hidden dependencies** (not displayed, but feed the measures above — build first)

```dax
Gross Sales Revenue =
CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] <> "Cancelled")

Refund Revenue = SUM(fact_returns[refund_amount])

List Value (Pre-Discount) =
CALCULATE(
    SUMX(fact_order_items, fact_order_items[quantity] * fact_order_items[unit_price]),
    fact_order_items[order_status] <> "Cancelled"
)

Discount Impact = [List Value (Pre-Discount)] - [Gross Sales Revenue]
```

**Data quality footnote value**
- % of Gross Sales Revenue excluded from category/product ranking due to `ghost_product_flag = TRUE` (known from Gross Margin % limitation: ghost revenue is 0.61% / €138,216 of Gross Sales Revenue)

### Layout

```
┌──────────────────────────────────────────────────────────┐
│  Sales & Product Performance                               │
│  [same date filter as Exec Overview, same header style]    │
├───────────────────────────────┬────────────────────────────┤
│                                 │                            │
│  Revenue by Category            │  Top 10 Products            │
│  (horizontal bar, sequential    │  (horizontal bar, ranked,   │
│   gradient, darkest = top)      │   revenue-sorted)            │
│                                 │                            │
├───────────────────┬─────────────┴────────────────────────────┤
│ Revenue by Channel  │  Discount Rate % by Channel              │
│ (bar, orange on     │  (bar, highlight worst offender          │
│  best channel)      │   in orange)                              │
├─────────────────────┴────────────────────────────────────────┤
│ Footnote: X% of revenue excluded from ranking (ghost-flagged)  │
└──────────────────────────────────────────────────────────────┘
```

Category and Top Products carry the "what's driving revenue" half (top row, largest weight). Channel and Discount answer "what's dragging on it" (bottom row, supporting). No trend chart here — that's owned by Executive Overview.

**Open decision — not yet resolved:** Revenue by Subcategory as a drill-through on the Category chart, vs. a separate visual. Default leaning: drill-through, to avoid crowding the page.

---

## Page 3: Customer Behavior

### Business question

**Big question:** Are we earning repeat business, or just acquiring one-time buyers?

**Sub-questions:**
1. How many distinct customers do we have, and how much revenue does each generate on average?
2. What share of customers come back to buy again?
3. Which countries are most valuable?
4. Do loyalty members behave differently than non-members? *(explicit CLAUDE.md EDA question)*
5. Is this picture reliable, or distorted by unmatched/duplicate customers?

### DAX measures needed

**KPI cards**

```dax
Distinct Customers (Deduped) =
CALCULATE(DISTINCTCOUNT(dim_customer[canonical_customer_key]), dim_customer[customer_key] <> -1)

Revenue per Customer = DIVIDE([Net Revenue], [Distinct Customers (Deduped)])

Repeat Purchase Rate =
DIVIDE(
    CALCULATE(
        [Distinct Customers (Deduped)],
        FILTER(
            VALUES(dim_customer[canonical_customer_key]),
            CALCULATE(DISTINCTCOUNT(fact_order_items[order_id])) > 1
        )
    ),
    [Distinct Customers (Deduped)]
)
```

**Revenue by Country / Loyalty / Age Group** — no dedicated measure. All three reuse `Net Revenue`, sliced by `dim_customer[country]`, `dim_customer[loyalty_member]`, or `dim_customer[age_group]`. Every slice must filter `customer_key <> -1` (unmatched customer) — per `BUSINESS_METADATA.md`, orders with `customer_key = -1` are valid for total revenue but must not be used in customer segmentation.

**Deliberately not added:** rolling/YoY versions of `Repeat Purchase Rate` or `Distinct Customers (Deduped)` — these are cumulative-membership measures, and naive `SAMEPERIODLASTYEAR` time-shifting on them is a known DAX trap that silently produces a wrong number.

### Layout

```
┌──────────────────────────────────────────────────────────┐
│  Customer Behavior                                         │
│  [same date filter, same header style]                     │
├───────────────────┬───────────────────┬─────────────────────┤
│ Distinct Customers  │ Revenue per        │ Repeat Purchase     │
│ (Deduped)           │ Customer           │ Rate                 │
├───────────────────┴───────────────────┴─────────────────────┤
│                                                                │
│   Net Revenue by Country                                      │
│   (horizontal bar, sequential gradient, darkest = top)        │
│                                                                │
├───────────────────────────┬────────────────────────────────────┤
│ Loyalty vs Non-Loyalty       │ Net Revenue by Age Group           │
│ (Net Revenue + Net AOV,      │ (bar chart)                        │
│  side-by-side bars)          │                                      │
├─────────────────────────────┴────────────────────────────────────┤
│ Footnote: customer_key = -1 (unmatched) and duplicate customers   │
│ excluded via canonical_customer_key                                │
└────────────────────────────────────────────────────────────────┘
```

Three KPI cards carry the headline customer numbers. Country breakdown is the main chart (largest weight — "which customers matter"). Loyalty and Age Group are supporting comparisons, side by side since they answer related but distinct sub-questions.

---

## Page 4: Returns & Revenue Risk

### Business question

**Big question:** How much of our reported revenue is actually at risk from returns, and where is that risk concentrated?

**Sub-questions:**
1. What is the gap between orders that *look* returned/refunded by status and the money that was *actually* refunded?
2. What % of revenue is lost to real, cash-based refunds?
3. Is return risk trending up or down over time?
4. Which product categories drive the most returns?
5. What are customers actually returning items for?
6. If returns or discounting worsen (or improve), how much Net Revenue is actually at stake?

Sub-question 1 is the page's central finding: order-status `Returned`/`Refunded` line value totals €4.63M, but `fact_returns.refund_amount` is only €914K — a €3.7M gap that Executive Overview signposts but doesn't explain.

**Date scope note:** the €4.63M / €914K figures are **full-dataset** (2021–2024), checked live 2026-07-18 — not H1 2024. They predate the H1-specific reporting section built later (2026-07-28/29) and can't be H1 2024 alone: €4.63M is larger than all of H1 2024's Net Revenue (€3.03M). This chart should default to the report's full date range, not the Jan–Jun comparable filter used elsewhere — state the period explicitly in the chart subtitle so it's never assumed to match the Executive Overview's H1 comparison strip.

### DAX measures needed

**KPI cards**

```dax
Refund Revenue = SUM(fact_returns[refund_amount])

Return Rate = DIVIDE([Refund Revenue], [Gross Sales Revenue])

Return Rate YoY =
VAR RRLY = CALCULATE([Return Rate], SAMEPERIODLASTYEAR(dim_date[full_date]))
RETURN [Return Rate] - RRLY
```

**"Looks returned" vs "actually refunded" — the central chart**

```dax
Returned Order Value =
CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] = "Returned")

Refunded Order Value =
CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] = "Refunded")
```

Plotted alongside `Refund Revenue` (already defined above) — three bars: Returned Order Value, Refunded Order Value, Refund Revenue. Orange highlight goes on `Refund Revenue`, since that's the real cash-impact number, not the two status-based ones.

**Refund Revenue by Category / Reason** — no dedicated measure. Reuse `Refund Revenue`, sliced by `dim_product[category]` (via `fact_returns[product_key]`) or `dim_return_reason[reason_category]`.

**Return Count** (operational detail, not headline — small multiple or tooltip only)

```dax
Return Count = CALCULATE(COUNTROWS(fact_returns), fact_returns[ghost_order_flag] = FALSE)
```

Note the asymmetry: `Refund Revenue` (€) has no ghost-flag filter, but `Return Count` (operational event count) excludes `ghost_order_flag = TRUE`. Keep this distinction — don't "fix" it into consistency, it's intentional.

**Hidden dependency**

```dax
Gross Sales Revenue =
CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] <> "Cancelled")
```

**What-if analysis — Return Rate & Discount Rate scenario**

Two Power BI parameters (Modeling tab → New Parameter → Numeric range), each ±5 percentage points, step 0.5, default 0:
- `Return Rate Adjustment (pp)`
- `Discount Rate Adjustment (pp)`

```dax
Simulated Gross Sales Revenue =
VAR DiscAdj = SELECTEDVALUE('Discount Rate Adjustment (pp)'[Discount Rate Adjustment (pp) Value], 0) / 100
VAR SimDiscRate = [Discount Rate %] + DiscAdj
RETURN [List Value (Pre-Discount)] * (1 - SimDiscRate)

Simulated Refund Revenue =
VAR RetAdj = SELECTEDVALUE('Return Rate Adjustment (pp)'[Return Rate Adjustment (pp) Value], 0) / 100
VAR SimReturnRate = [Return Rate] + RetAdj
RETURN SimReturnRate * [Simulated Gross Sales Revenue]

Simulated Net Revenue =
[Simulated Gross Sales Revenue] - [Simulated Refund Revenue]

Net Revenue Impact (What-If) =
[Simulated Net Revenue] - [Net Revenue]
```

Both scenarios flow through the same discount/return chain used elsewhere in this model (`List Value (Pre-Discount)` → `Discount Rate %` → `Gross Sales Revenue` → `Refund Revenue` → `Net Revenue`), so a combined scenario (e.g. "discount up 2pp, returns down 1pp") is just moving both sliders at once — no separate combined measure needed. `Discount Rate %` and `List Value (Pre-Discount)` are defined on the Sales & Product Performance page; this section reuses them, doesn't redefine them.

### Layout

```
┌──────────────────────────────────────────────────────────┐
│  Returns & Revenue Risk                                    │
│  Full date range (2021–2024) — NOT the Jan–Jun comparable  │
│  filter used on Executive Overview                          │
├───────────────────┬───────────────────┬─────────────────────┤
│ Refund Revenue      │ Return Rate        │ Return Rate YoY      │
│                     │                    │ (pp delta)           │
├───────────────────┴───────────────────┴─────────────────────┤
│                                                                │
│  "Looks Returned" vs "Actually Refunded"                      │
│  Returned Order Value | Refunded Order Value | Refund Revenue │
│  (grouped bar, orange highlight on Refund Revenue)             │
│  [this is the €4.63M vs €914K finding — full width, main chart]│
│                                                                │
├───────────────────────────┬────────────────────────────────────┤
│ Refund Revenue by Category   │ Refund Revenue by Reason           │
│ (bar, sequential gradient)   │ (bar, dim_return_reason categories)│
├─────────────────────────────┴────────────────────────────────────┤
│ What-If: Return Rate Adj. [slider]  Discount Rate Adj. [slider]   │
│ Net Revenue Impact (What-If): €X    (card, below the fold —       │
│ interactive tool, not a headline number)                           │
├─────────────────────────────────────────────────────────────────┤
│ Footnote: return ≠ refund — a return is the product coming back, │
│ a refund is money paid back; they are not always the same event  │
└────────────────────────────────────────────────────────────────┘
```

The "Looks Returned vs Actually Refunded" chart carries the page's Big Idea and gets full width and top visual weight — this is the single most important finding in the whole report, not a supporting detail. Category and Reason breakdowns are drill-down support, answering "where" once the "how much" is established. The What-If scenario strip sits below all of that, deliberately last — it's an exploratory tool for someone who wants to probe "what if," not something that should compete with the real, validated numbers above it for attention.

---

## Deferred / Out of scope

Measures that don't belong to any of the 4 pages above.

**Future 5th page candidate — "Order Funnel":** answers a real, distinct question — "how much demand exists before cancellations strip it down to realized revenue?" — that none of the current 4 pages ask. Not built now because it doesn't fit any existing page's Big Idea without diluting it; a dedicated page is the right container if this gets picked up later.

```dax
Gross Order Value (GOV) = SUM(fact_order_items[line_total])

Cancelled Revenue =
CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] = "Cancelled")

Cancelled Rate = DIVIDE([Cancelled Revenue], [Gross Order Value (GOV)])

Placed Orders = DISTINCTCOUNT(fact_order_items[order_id])

Cancelled Orders =
CALCULATE(DISTINCTCOUNT(fact_order_items[order_id]), fact_order_items[order_status] = "Cancelled")

Gross AOV = DIVIDE([Gross Sales Revenue], [Completed Orders])

Gross Units Sold =
CALCULATE(SUM(fact_order_items[quantity]), fact_order_items[order_status] <> "Cancelled")
```

**Dropped — not just deferred:** plain `YoY Growth %` and a raw `Net Revenue LY` (prior-year, no period-length matching) are superseded by the Comparable versions already in use on Executive Overview. A standard `TOTALYTD`/`Net Revenue Full Year` approach is actively risky, not just redundant: it would reintroduce a "2024 reads as a fake ~50% decline" bug, since `dim_date` only has 6 months of 2024. If a genuine multi-year finance calendar view is needed later, rebuild from the Comparable pattern (`Net Revenue Comparable YTD`, defined on Executive Overview), not from raw YTD.

**Out of scope by earlier decision:**
- Payments measures (`Realized Revenue (Paid)`, `Payment Success Rate`) — no Payments page was designed.
- Marketing measures (Touchpoints, Clicks, Conversions, CTR, Conversion Rate) — cut from report scope ("dilutes the exec story" from a Marketing page not being pursued).

---

## Open decisions log

| Decision | Status | Notes |
|---|---|---|
| Net Revenue naming | Open | `BUSINESS_METADATA.md` calls it "Cash-Based Net Revenue"; DAX draft and this file call it "Net Revenue." Pick one before any page ships with the name visible. |
| Return Rate basis | Open | Revenue-based (current default, no cross-fact join) vs. order-count-based (`TREATAS`, more expensive). Revenue-based is the working default across this file. |
| Subcategory drill-through vs. separate visual | Open | Sales & Product Performance page. Default leaning: drill-through. |

---

## Known limitations to disclose on the dashboard

State these visibly (footnotes, not buried) — they affect how the numbers should be read:

- **2024 is a half-year only.** `dim_date` runs 2021-01-01 → 2024-06-30. Any full-year comparison touching 2024 without the "Comparable" measures will read as a fake ~50% decline.
- **Generated data caution.** With 4 generated years, unnaturally clean seasonal patterns (e.g. identical November uplift every year) are more likely a generation artifact than real seasonality — flag rather than treat as a genuine trend.
- **Ghost-product revenue inflates Gross Margin %.** ~0.61% of Gross Sales Revenue (€138,216) carries €0 cost, inflating blended Gross Margin % by ~0.6pp.
- **Return-status vs. actual refund gap.** Order-status `Returned`/`Refunded` line value totals €4.63M, but actual `fact_returns.refund_amount` is €914K — a €3.7M gap between "looks returned" and cash actually returned. Central to the Returns & Revenue Risk page.
- **`raw_orders.country` is not usable for geography.** Randomly assigned per order, 89.9% inconsistent with the customer's actual country. Always use `dim_customer.country`.
