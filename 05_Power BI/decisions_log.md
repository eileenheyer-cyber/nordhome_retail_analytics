# NordHome Dashboard — Decisions Log

Documents *why* the model/report is built the way it is — the reasoning behind specific measures, chart choices, and design calls. Companion file: [dax_measures.md](dax_measures.md) for the measure definitions themselves. This supersedes [power_bi_modelling_decisions.md](archive/power_bi_modelling_decisions.md) and [dashboard_design.md](archive/dashboard_design.md) as the current source — both were written against an earlier, less mature version of the model.

---

## Executive Overview Dashboard

### Viewer

CEO / COO — senior leadership who need a health check, not drill-down detail.

### Big question + business questions

**Big question (10-second takeaway):** Is the business healthier this half than last year, and where's the biggest risk to revenue?

**Business questions this page answers:**
- How is net revenue trending this half compared to last year, and where might H2 land if the current trend holds?
- Are the other core health metrics — average order value, gross margin, completed orders, return rate — improving or declining year-over-year?
- How much revenue is lost *after* a sale closes (cancellations, returns, refunds), and which of those three is the biggest leak?
- What's the single most important win, loss, and next action a stakeholder should take away from the page?

### Decisions

#### H2 Revenue Forecast — flat run-rate, not seasonal

**Decision:** `H2 Revenue Forecast` projects each future H2 (Jul–Dec) month by taking **last year's actual revenue for that same month** and scaling it by **this year's overall H1 growth rate** — it does not model seasonality.

```dax
H2 Revenue Forecast =
VAR H1Growth = CALCULATE([YoY Revenue Growth], ALL(dim_date[month_number]), ALL(dim_date[month_name]))
VAR HasOrderActivity = NOT ISBLANK([Gross Order Value (GOV)])
VAR CurrentMonth = SELECTEDVALUE(dim_date[month_number])
RETURN
IF(
    CurrentMonth >= 7 && NOT HasOrderActivity,
    CALCULATE([Net Revenue], SAMEPERIODLASTYEAR(dim_date[full_date])) * (1 + H1Growth),
    BLANK()
)
```

- `H1Growth` strips month-level filter context (`ALL(...)`) so it always evaluates to one single number: the whole H1-vs-last-year growth rate, not a per-month figure.
- The `IF` only fires for months that are (a) July or later, and (b) have no real order data yet — so the forecast line picks up exactly where the actual line stops, never overlapping it.

**Why this approach:** checked 3 years of monthly revenue history before designing this. H2/H1 ratio ≈ 100.7% against ~8% month-to-month noise — there's no real seasonal pattern to model, just noise. A seasonal-decomposition forecast would have been fitting that noise, not signal. A flat growth-rate projection over last year's actual shape is the honest choice given what the data actually shows.

**Trade-offs:**
- Labeled **"H2 estimate"** on the chart, not "forecast" — sets the right expectation that this is a simple projection, not a modeled prediction.
- `fact_order_items` has no rows after Jun 30, 2024 — H1 figures are real, but the forecast logic depends on that cutoff being correct; if actuals ever extend further, the `HasOrderActivity` check needs no change (it already defers to real data when present), but the cutoff assumption is worth re-checking each refresh.
- Would need to be redesigned if a genuine seasonal pattern ever emerges in the data (currently there isn't one).

#### Win/Loss/Action insight row — static text, not DAX-generated

**Decision:** removed the `Executive Win Insight` / `Executive Watch Insight` / `Executive Action Insight` measures and replaced the insight-row tiles with hand-written, static text.

**Why this approach:** the Win measure's own logic correctly detected "no headline metric improved this half" (all 5 KPIs were negative that period) but the tile was still labeled green **"● WIN"** — which reads as good news regardless of what the sentence underneath actually says. Auto-generated narrative text is powerful (it can't go stale the way hardcoded text can), but it needs its edge cases checked against how the *label and color around it* will be read, not just whether the sentence is grammatically correct.

**Trade-offs:**
- Gains: an executive-facing tile that's always been reviewed by a human before it ships — judged the safer default for this row.
- Costs: static text does **not** update automatically as the underlying numbers change each period — it needs manual review/rewrite whenever the data is refreshed. Right approach only if that manual step is reliably part of the refresh process.

#### Revenue-lost breakdown — bar chart, not donut/pie

**Decision:** cancellations/returns/refunds share of net revenue is shown as a horizontal bar chart, sorted descending by value.

**Why this approach:** the three values are fairly close in magnitude (~7.4% / 5.9% / 4.7%). Bar length (position/length encoding) preserves small differences between close values; a donut or pie chart (angle/area encoding) would visually flatten them, making it harder to see that cancellations are meaningfully the largest leak.

**Trade-offs:**
- The bar chart's gradient fill had to be applied manually in Desktop's Format pane — a file-based `fillRule` didn't render. If this page is ever rebuilt from files again, that gradient will need to be reapplied by hand.

#### Revenue-lost denominator — Gross Order Value (GOV), for all three components

**Decision:** every "% of revenue lost" measure — cancelled, returned and refunded — divides by `Gross Order Value (GOV)`. This supersedes the previous mix, where `Cancelled Share of Net Revenue` and `Returned Share of Net Revenue` divided by `Net Revenue` while `Refund Rate` divided by `Gross Sales Revenue`.

```dax
Cancelled % of GOV = DIVIDE ( [Cancelled Order Value], [Gross Order Value (GOV)] )
Returned % of GOV  = DIVIDE ( [Returned Order Value],  [Gross Order Value (GOV)] )
Refunded % of GOV  = DIVIDE ( [Refunded Order Value],  [Gross Order Value (GOV)] )

Lost Revenue %     = DIVIDE ( [Lost Revenue], [Gross Order Value (GOV)] )
```

**Why this approach:** the governing rule is that **a percentage is only a "share of" something if the numerator sits inside the denominator**. If the base has already had the numerator removed, the result isn't a share — it's a ratio of two different things, and it can't be read, compared or added. Tested against the three candidate bases:

| Base | Contains Cancelled? | Contains Returned? | Contains Refunded? |
|---|---|---|---|
| **GOV** (€12,446,470) | yes | yes | yes |
| Gross Sales Revenue (€11,593,455) | **no** — defined as `order_status <> "Cancelled"` | yes | yes |
| Net Revenue (€10,679,255) | **no** | yes | **no** — refunds already deducted |

Only GOV passes for all three. Dividing cancellations by Gross Sales Revenue asks "cancellations are what % of the orders that weren't cancelled?", which is not a meaningful question.

Net Revenue is the weakest of the three because it is what remains *after* the losses. Dividing a loss by the survivors makes the metric non-linear — the denominator shrinks at the same time the numerator grows:

```
If losses doubled...
  GOV base:      16.80%  ->  33.60%   (exactly 2x, as expected)
  Retained base: 20.19%  ->  50.61%   (2.5x — overreacts)
```

It is also unbounded: a 90% loss rate would read 900%. The GOV base is bounded 0–100% and moves proportionally, which is what an executive audience expects of a percentage.

The base choice alone moves the headline number by nearly three points on identical underlying data — which is why it had to be settled on principle rather than on which figure looked better:

| Denominator | Cancelled | Returned | Refunded | Total |
|---|---|---|---|---|
| **GOV** | 6.85% | 4.85% | 5.10% | **16.80%** |
| Gross Sales Revenue | 7.36% | 5.21% | 5.47% | 18.04% |
| Net Revenue *(previous)* | 7.99% | 5.65% | 5.94% | 19.58% |

**Why all three must share one base** — this is a correctness requirement, not a style preference:

- **Addition.** `Revenue at Risk %` summed three fractions carrying two different bases. That produces a figure that is not a percentage *of* anything.
- **Comparison.** "Cancelled 8.0% vs Refunded 7.9%" reads as a near-tie, but the two were measured against differently-sized pools, so the comparison was never real.
- **Stacking.** In a stacked column chart, segments drawn to different scales assert visually that they are parts of one whole when they are not.

**How the inconsistency arose:** each measure was written at a different time, answering a different local question — `Refund Rate` divided by Gross Sales Revenue because "refunds come out of sales", `Cancelled Share of Net Revenue` divided by Net Revenue because it was built for a different visual. Each was defensible in isolation; they only broke once placed in the same visual. **General lesson: measures that will ever appear in one visual, or ever be summed, must be designed as a set rather than written one at a time.**

**Sub-decision — "Refunded" is sourced from `order_status`, not `fact_returns`:** the denominator only holds together if the three numerators are mutually exclusive. `Refunded Order Value` is therefore defined as `fact_order_items[order_status] = "Refunded"` (€634,397), *not* `SUM(fact_returns[refund_amount])` (€914,199). Checked in the source data: `fact_returns` rows are spread across every order status, including Cancelled — only 19% of Returned-status lines and 21% of Cancelled-status lines have a matching return row. Mixing the two sources double-counts refunds against cancellations and returns, so the slices would not sum to a whole. With all three drawn from `order_status`, GOV partitions cleanly into Retained + Cancelled + Returned + Refunded.

**Trade-offs:**
- Sourcing refunds from `order_status` **loses the return-reason detail** that `fact_returns` + `dim_return_reason` provide. Reason analysis ("why did they return it") stays valid but must be kept as an explicitly separate lens, on its own visual, never mixed into the loss-rate stack.
- `Revenue at Risk %` and its component measures have now been **removed**. Retiring them required first repointing four report objects and creating `Lost Revenue % LY`, since `Revenue at Risk % LY` depended on the measure being deleted — a reminder that "delete one measure" is rarely one step.
- The denominator re-evaluates inside the visual's filter context, so a monthly chart shows each month's loss against that month's opportunity. This is intended. Monthly bars therefore do **not** sum to the annual rate — a version that did would need `REMOVEFILTERS` on `dim_date`.

**Implemented — 1 Sep 2026.** The decision above is live in the model, not just recorded:

- **Created:** `Refunded Order Value`, `Lost Revenue`, `Lost Revenue %`, `Lost Revenue % LY`, `Refunded % of GOV` — all with descriptions populated.
- **Renamed + rebased:** `Cancelled Share of Net Revenue` → `Cancelled % of GOV`, `Returned Share of Net Revenue` → `Returned % of GOV`. Both now divide by GOV.
- **Deleted:** `Revenue at Risk %`, `Revenue at Risk % LY`, `Revenue Bridge Value`, `Revenue Risk Breakdown Value`. Model went 134 → 130 measures and reloads clean.
- **Repointed:** the Executive Overview clustered-column chart, the Return & Revenue Risk line chart and card, and one bookmark, from `Revenue at Risk %` / `% LY` to `Lost Revenue %` / `% LY`.
- **Donut switched to euros.** The Executive Overview donut now plots `Cancelled Order Value` / `Returned Order Value` / `Refunded Order Value` rather than the three `% of GOV` measures — otherwise slice labels read `6,1% (28,31%)`, two different percentages nobody would disentangle. Euro values give one amount plus one share (`€853K (40,8%)`), and the centre card still carries `Lost Revenue %` for the headline rate.
- **Currency formatting normalised.** `Cancelled Order Value` and `Returned Order Value` carried no `formatString`, so they rendered as bare digits beside `Refunded Order Value`'s `€634.397,33`. Both now use the same euro format string, verified byte-identical.
- **Left alone deliberately:** `Refund Rate` and `Return Rate` — valid standalone KPIs on the `fact_returns` lens; their problem was never the denominator but a numerator that overlaps cancelled and returned lines, so they can't serve a mutually-exclusive breakdown.

Verified against the live model before the rewrite:

```
GOV                          €12,446,469.63
  Cancelled                      853,015.06    6.85%
  Returned                       603,757.35    4.85%
  Refunded                       634,397.33    5.10%
  Lost Revenue                 2,091,169.74   16.80%

Sum of the three components = 16.801308%
Lost Revenue %              = 16.801308%   exact match
```

**Follow-through — both closed:**
1. **Orphaned helper tables deleted.** `Revenue Risk Categories` and `Revenue Risk Breakdown` removed (table files plus `ref table` entries in `model.tmdl`). Model went 23 → 21 tables and reloads clean.
2. **Insight textbox rewritten** to: *"Lost revenue stands at 16,9% of gross order value in 2024 — above the 10–15% healthy range — with cancellations the largest driver (€116K, 6,7%), ahead of returns (€90K, 5,2%) and refunds (€85K, 5,0%)."*

**The rebase changed the story, not just the numbers.** The old copy named **refunds** the largest driver at €142K — drawn from `fact_returns[refund_amount]`, the overlapping lens. On the status-based, mutually-exclusive lens the ranking inverts:

| 2024 | Value | % of GOV | Old copy said |
|---|---|---|---|
| Cancelled | €115,568 | 6.70% | €116K, 7,9% — *second* |
| Returned | €89,966 | 5.21% | €90K, 6,1% — *third* |
| Refunded | €85,314 | 4.95% | €142K, 9,7% — *largest* |
| **Lost** | **€290,848** | **16.86%** | 23,7% |

Refunds were overstated by ~67% (€142K vs €85K) because the `fact_returns` figure counts refunds booked against cancelled and returned orders too. The recommended action — audit cancellations first — was already the right call, and is now actually supported by the data rather than contradicted by it. **This is the clearest evidence in the project that a denominator/numerator error is not cosmetic: it inverted the ranking an executive would act on.**

**Carried-over caveat:** the "10–15% healthy range" benchmark predates this work and has no recorded source. A benchmark whose denominator is unknown cannot be safely compared to a GOV-based figure — the exact error this entry exists to prevent. Kept for now because it is a business judgement, not a calculation, but it should either be sourced or dropped.

---

## Dataset characteristics — what this data can and cannot support

*Not tied to one page. Read this before starting any new analysis on NordHome data.*

### Product, subcategory, channel and brand are uniformly random — concentration analysis is not viable

**Finding:** revenue in this dataset is distributed near-uniformly across every product-related dimension. There is no Pareto pattern at any grain, and there cannot be one, because the data generator assigned these fields at random rather than modelling purchasing behaviour.

Evidence, measured on `Gross Sales Revenue` (order lines excluding cancelled):

| Grain | Concentration | A real Pareto |
|---|---|---|
| Subcategory (16) | top 3 = 28.3%; needs 12 of 16 for 80% | top ~20% = ~80% |
| Product (1,090) | top 20% = 24.9%; needs 816 of 1,091 for 80% | top ~20% = ~80% |

Revenue by decile of products, ranked best to worst — **12.88, 11.69, 11.11, 10.61, 10.20, 9.79, 9.32, 8.85, 8.28, 7.27%**. Almost flat. Best real product €16,562, worst €5,132 — a **3.2× spread across 1,090 products**, coefficient of variation **0.161**.

Two other dimensions make it conclusive:

```
SALES CHANNEL                 BRAND (11)
Phone         25.14%          CozyLiving  11.65%
Marketplace   25.07%          HausStil    11.15%
Mobile App    24.99%          NordHome    10.78%
Website       24.80%          UrbanNest   10.23%
```

Four channels inside 0.34 percentage points of exactly 25%; eleven brands clustered on 1/11 = 9.1%. Real retail never looks like this — genuine product revenue follows a power law, top deciles carry 40–60%, CV runs above 1.5, and best-to-worst spreads reach 1000×. Four channels landing on 25.0% requires a random number generator, not customers.

**Where the generator *did* put signal:** `order_status` is deliberately weighted — Completed 54.85%, Shipped 20.52%, Processing 7.83%, Cancelled 6.85%, Refunded 5.10%, Returned 4.85%. That is the one dimension carrying real structure, and it is exactly where the revenue-loss work landed. That analysis is sound; this one is not.

**Decision:**
- **Do not build** ABC/Pareto classification, top-seller analysis, long-tail analysis, SKU rationalisation, channel-preference or brand-performance analysis. All will return flat, and flatness here is an artefact, not a result.
- **Worth pursuing:** order status and revenue loss (confirmed), returns by reason, margin and discount leakage, time trends, marketing funnel. Test each first — if shares come out near-uniform, the generator didn't model it.
- The Pareto measures were built, verified against the live model, and then **discarded — never saved to the file**. They returned correct numbers, but correct numbers that reveal nothing are still clutter. A measure earns its place by answering a question someone will ask; these answered one whose answer is "no pattern here", and that answer belongs in this log rather than in the model. The DAX is preserved below so nothing is lost by deleting them.

**The pattern, kept for reuse** — running total over categories ranked by value, the standard Pareto construction:

```dax
Revenue Cumulative (Subcategory) =
VAR CurrentRev = [Gross Sales Revenue]
VAR Summary =
    ADDCOLUMNS (
        ALLSELECTED ( dim_product[subcategory] ),
        "@Rev", [Gross Sales Revenue]
    )
RETURN
    IF (
        NOT ISBLANK ( CurrentRev ),
        SUMX ( FILTER ( Summary, [@Rev] >= CurrentRev ), [@Rev] )
    )
```

```dax
Revenue Cumulative % (Subcategory) =
DIVIDE (
    [Revenue Cumulative (Subcategory)],
    CALCULATE ( [Gross Sales Revenue], ALLSELECTED ( dim_product[subcategory] ) )
)
```

`ALLSELECTED` builds a table of every category currently visible — respecting slicers, ignoring the row being evaluated. For each bar it sums every category whose value is greater than or equal to its own, which is "everything to my left, plus me" once the axis is sorted descending. The `IF` stops the line drawing past the last bar. Swap `dim_product[subcategory]` and `[Gross Sales Revenue]` for any other category/measure pair to reuse it.

Two caveats to carry with the pattern: `>=` double-counts exact ties, so add a tiebreaker if values can repeat; and the visual **must** be sorted by the value measure descending, or the cumulative line is meaningless.

**Framing correction — important.** The first instinct was to title the subcategory Pareto *"No single subcategory carries revenue"* and present it as a diversification insight: no concentration risk, no single point of failure. **That framing was wrong and must not ship.** It reads a data-generation artefact as a business property. Presenting uniform randomness to an executive as evidence of a healthily diversified portfolio would be a worse error than the mixed denominators fixed earlier — that one miscalculated a number, this one would invent a conclusion.

**General lesson: test the distribution's shape before committing to a chart type that assumes one.** A Pareto chart presupposes concentration; a donut presupposes parts summing to a meaningful whole; a trend line presupposes signal above noise. Three minutes checking top-20% share, decile spread and coefficient of variation established that this chart would be empty before any DAX was written.

### `loyalty_member` is randomly assigned — loyal vs non-loyal comparison is not viable

Verified 2026-09-04 by splitting every available metric by `dim_customer[loyalty_member]`, with the `-1` placeholder excluded:

| Metric | Non-loyal | Loyal |
|---|---|---|
| Active customers | 3,931 | 3,901 |
| Orders per customer | 3.70 | 3.61 |
| Revenue per customer | €1,367 | €1,321 |
| Net AOV | €369.96 | €366.20 |
| Repeat purchase rate | 39.9% | 38.8% |
| Return rate | 5.07% | 5.37% |
| Cancel rate | 6.59% | 7.17% |
| Discount rate | 15.38% | 15.20% |
| Gross margin | 36.26% | 36.01% |
| Units per order | 3.72 | 3.69 |
| Churn rate | 67.5% | 67.3% |

Channel mix is uniform too — roughly 3,550–3,670 non-cancelled orders in *every* channel for *both* groups — as is marketing engagement (CTR 5.00% vs 4.93%, conversion 2.27% vs 2.31%, touchpoints per customer 75.93 vs 75.83).

Every gap is 1–2%, with non-members marginally ahead on most. That is the signature of a coin-flip column, not of a programme with real effects.

**Decision: no loyalty-split measures were built.** Three were drafted and none created — `Net AOV (Loyal)`, `Net AOV (Non-Loyal)`, and a single `Net AOV (Known Customers)` intended to resolve against a `loyalty_member` axis.

**Why not.** The measures would have worked correctly and returned a 1% difference that means nothing. Shipping them creates a standing invitation to read noise as a finding — a card reading "Members: €366 · Non-members: €370" invites someone to ask why members spend less, and there is no answer because there is no effect.

**What to do instead.** If a loyalty visual is wanted anyway, title it so it states the null result — "Loyalty membership shows no measurable difference" — rather than implying an effect. Order Frequency Band is the split on this data that does carry signal, and it is where the customer-value story actually lives.

**Placeholder trap.** The `customer_key = -1` "Unknown Customer" row carries `loyalty_member = FALSE`, so it silently joins the non-loyal group: 232 orders at a €648 AOV, which lifts that group's Net AOV from €369.96 to €374.32. Any loyalty split must filter it out with `dim_customer[is_unknown_customer] = FALSE()`.

### Orphaned product keys — ~€1.08M unattributable

**Finding:** 6,575 of 75,473 `fact_order_items` rows (8.7%) carry a `product_key` matching no row in `dim_product`, not even the `-1` placeholder.

**Decision:** top-line KPIs are left unaffected (they sum the fact table regardless of the join), but any product- or category-level breakdown silently excludes this revenue — adding up a category breakdown will not reconcile to the total, and that gap should be disclosed wherever a category/product view is presented as complete. Full write-up: `Data Quality Issue - Orphaned product_key.md`.

### Order dates are uniformly random — no customer lifecycle structure

**Finding:** order dates were generated independently of customer registration, so there is no genuine tenure, cohort, or lifecycle structure in the data.

**Decision:** cohort retention curves and time-since-acquisition analysis are not valid on this dataset and should not be built. Period-scoped metrics (orders in a window, churn as of a date) remain fine, since they don't depend on a lifecycle assumption.

---

## Measure hygiene — 2026-09-04

Seven measures removed after auditing which of the 150 were bound to a visual or referenced by another measure. Of those, 68 were on a page and 38 were building blocks feeding other measures; the rest were unreferenced.

### The `Dax Practice` folder — 5 measures removed

`Refined Category Sales`, `Revenue_IgnoreProductFilters`, `Revenue_GloableAll`, `High Revenue Sales`, `High Revenue ALL`.

Scratch work from learning filter context, never bound to a visual, never referenced. Kept here because the pairs are worth re-reading:

```dax
Refined Category Sales      = CALCULATE([Gross Sales Revenue], KEEPFILTERS(dim_product[category] = "Gifts"))
Revenue_IgnoreProductFilters = CALCULATE([Gross Sales Revenue], REMOVEFILTERS(dim_product[category]))
Revenue_GloableAll          = CALCULATE([Gross Sales Revenue], ALL(dim_customer), ALL(dim_product))
High Revenue Sales          = CALCULATE([Gross Sales Revenue], FILTER(dim_product, [Gross Sales Revenue] > 1500))
High Revenue ALL            = CALCULATE([Gross Sales Revenue], FILTER(ALL(dim_product), [Gross Sales Revenue] > 3000))
```

The first two contrast filter *intersection* against filter *removal*; the last two contrast `FILTER` respecting the current context against `FILTER` ignoring it.

**Why remove them.** A model where a third of the measures are unused is harder to hand over — every name in the field list is a claim that it matters. Practice code belongs in notes, not in a shipped semantic model.

### `Funnel Middle` and `Funnel Right` — 2 measures removed

Both were abandoned attempts at the centred-funnel technique. The working chart pairs **`Funnel Left` with `Funnel Value`**, and that pairing is correct:

```dax
Funnel Left =
VAR MaxValue = CALCULATE(MAXX('Funnel Stage', [Funnel Value]), REMOVEFILTERS('Funnel Stage'))
RETURN DIVIDE(MaxValue - [Funnel Value], 2)
```

`Funnel Left` is a transparent padding series placed **first** in the Values well, with `Funnel Value` second. With padding of (Max − Value)/2, the visible bar spans from (Max − Value)/2 to (Max + Value)/2 — centred on Max/2 at every stage, which is exactly the funnel taper.

- **`Funnel Middle` = `[Funnel Value] * 2`** belongs to a variant where the padding is computed differently. Stacked after the existing `Funnel Left`, it would have drawn bars at double width and destroyed the centring.
- **`Funnel Right` = `Max * 1.5`** is a fixed pad that does not vary by stage, so it could not centre anything.

**Why remove them.** Both were dead ends kept "in case", and their names imply they belong to the working technique. The next person to open the model would reasonably assume `Funnel Left` pairs with `Funnel Middle` — the comment inside `Funnel Left` said exactly that — and rebuild the chart wrong.

---

*Add new dashboard sections below the template, following the same Viewer / Big question / DAX measures / Decisions structure, whenever a new page is built.*
