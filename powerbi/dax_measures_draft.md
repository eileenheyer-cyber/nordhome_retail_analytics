# Power BI DAX Measures — Draft

Status: **draft, not yet reviewed or committed.** Proposed 2026-07-17, organized by fact table. Nothing here has been built in Power BI yet — this is the starting point for that session.

For column include/exclude decisions (which fields even make it into the model), see `power_bi_modelling_decisions.md`. This file is about what to calculate from the columns that were kept.

---

## Sales — `fact_order_items`

**Revenue KPI framework (adopted 2026-07-18):** a tiered GOV → Recognized Revenue → Net Revenue structure, adapted from a proposed generic e-commerce framework with one required fix to match this project's own validated data (`docs/business_rules/revenue_deduction_logic.md`, `BUSINESS_METADATA.md` §6):

- **Cancelled** → excluded from Recognized Revenue and Net Revenue entirely. Never charged.
- **Returned / Refunded** (`order_status`) → stay **in** Recognized Revenue. Not deducted at full `line_total` value — only the actual `fact_returns.refund_amount` is subtracted in Net Revenue. The original proposal filtered "recognized revenue" to `order_status IN ('Completed','Shipped')` only, which would have zeroed out €4.63M of Processing/Refunded/Returned line value — of which only €914K is ever actually refunded (checked live, 2026-07-18). That's the same over-deduction the project's own Method A vs. Method B validation already rejected (€300K–€590K/year too aggressive), just relocated into the revenue filter instead of a separate subtraction. Fixed to `order_status <> 'Cancelled'`.
- **Net Margin is explicitly documented as not calculable** in this project (no cost data beyond `unit_cost`). Don't build a "Net Margin" measure — only Gross Margin.

**Naming cross-reference:** `Gross Order Value` and `Gross Sales Revenue` below use the exact same names as `BUSINESS_METADATA.md` §6. `Net Revenue` here is `BUSINESS_METADATA.md`'s **"Cash-Based Net Revenue"** — that one name still differs, noted on its row so nobody reading both docs assumes it's a different number. Consider syncing `BUSINESS_METADATA.md`'s "Cash-Based Net Revenue" label to just "Net Revenue" in a follow-up so there's one name left to reconcile, not two.

| Measure | DAX | Why / doc cross-reference |
|---|---|---|
| Gross Order Value (GOV) | `SUM(fact_order_items[line_total])` | All rows, any status, including Cancelled. "What was ordered" — a demand/funnel number, not a revenue number. New tier, not previously in `BUSINESS_METADATA.md`. |
| Gross Sales Revenue | `CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] <> "Cancelled")` | Matches `BUSINESS_METADATA.md`'s **"Gross Sales Revenue"** exactly — same name, same formula. Post-discount (`line_total` already nets out `discount`), excludes only Cancelled. **No `ghost_product_flag` filter** — see correction below. |
| Net Revenue | `[Gross Sales Revenue] - [Refund Revenue]` | = `BUSINESS_METADATA.md`'s **"Cash-Based Net Revenue."** The main financial KPI — the number that should reconcile with `fact_payments`. |
| Cancelled Revenue | `CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] = "Cancelled")` | Not a deduction from anything above — it was never in Recognized/Net Revenue to begin with. Shown as a % of GOV (below) to track cancellation impact. |
| Cancelled Rate | `DIVIDE([Cancelled Revenue], [Gross Order Value (GOV)])` | New — the "% of GOV" framing from the proposed framework. |
| Returned Order Value | `CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] = "Returned")` | Operational-only, kept from the previous draft per `BUSINESS_METADATA.md`'s explicit ask to track "Order Status Impact" separately (§6, "Treatment of Order Statuses"). **Not** a revenue deduction — compare against `Refund Revenue` to see the partial-refund gap. |
| Refunded Order Value | `CALCULATE(SUM(fact_order_items[line_total]), fact_order_items[order_status] = "Refunded")` | Same as above for the `Refunded` status. |
| Return Rate | `DIVIDE([Refund Revenue], [Gross Sales Revenue])` | Defined in the Returns section below, referenced directly here — no separate "Returned Revenue" alias measure (removed 2026-07-18, was a pure duplicate of `Refund Revenue` with no functional difference). = `BUSINESS_METADATA.md`'s **"Revenue Return Rate"** / `revenue_deduction_logic.md`'s **"Deduction Rate."** Pick one name for the dashboard. |
| List Value (Pre-Discount) | `CALCULATE(SUMX(fact_order_items, fact_order_items[quantity] * fact_order_items[unit_price]), fact_order_items[order_status] <> "Cancelled")` | Support measure for Discount Impact below. Filtered to non-Cancelled to match Gross Sales Revenue's population. |
| Discount Impact | `[List Value (Pre-Discount)] - [Gross Sales Revenue]` | List value minus actual (line_total) — margin given away via `discount`. |
| Discount Rate % | `DIVIDE([Discount Impact], [List Value (Pre-Discount)])` | Slice by `sales_channel` to see which channel discounts hardest — both columns are denormalized directly on the fact table, no join needed. |
| Placed Orders | `DISTINCTCOUNT(fact_order_items[order_id])` | All orders regardless of status — total demand. |
| Completed Orders | `CALCULATE(DISTINCTCOUNT(fact_order_items[order_id]), fact_order_items[order_status] <> "Cancelled")` | **Use this as the AOV denominator**, not Placed Orders — must match the population Gross Sales Revenue is summed over. |
| Cancelled Orders | `CALCULATE(DISTINCTCOUNT(fact_order_items[order_id]), fact_order_items[order_status] = "Cancelled")` | |
| Gross AOV | `DIVIDE([Gross Sales Revenue], [Completed Orders])` | Average basket value before refunds. |
| Net AOV | `DIVIDE([Net Revenue], [Completed Orders])` | Average realized order value after refunds. Label both AOV variants clearly on any visual. |
| Gross Units Sold | `CALCULATE(SUM(fact_order_items[quantity]), fact_order_items[order_status] <> "Cancelled")` | "Net Units Sold" (minus returned quantity) isn't calculable — `fact_returns` has no quantity column, only `refund_amount`. |
| COGS | `CALCULATE(SUMX(fact_order_items, fact_order_items[quantity] * RELATED(dim_product[unit_cost])), fact_order_items[order_status] <> "Cancelled", fact_order_items[ghost_product_flag] = FALSE)` | Cost of Goods Sold — feeds Gross Profit/Margin. Ghost rows excluded **structurally**: they map to `product_key = -1`, no real `unit_cost` exists. Uses `unit_cost`, never `list_price` (~zero correlation with unit_price — see modelling decisions doc). |
| Gross Profit | `[Net Revenue] - [COGS]` | Net revenue minus cost, not GOV/Gross-Merchandise-Revenue minus cost. |
| Gross Margin % | `DIVIDE([Gross Profit], [Net Revenue])` | Profit ÷ **net** revenue, not gross — gross as denominator would inflate the margin %. |
| Revenue by Channel / Shipping Method | *(no dedicated measure)* | Slice GOV / Gross Sales Revenue / Net Revenue by `sales_channel` and `shipping_method` — both denormalized directly onto `fact_order_items`, cheap slicers with no joins needed. |

**Correction (2026-07-18, part 1 — ghost flag):** earlier draft excluded `ghost_product_flag = TRUE` from every "clean" measure, copying the comment in `fact_order_items.sql` without checking whether it actually applies to top-line revenue. Checked live: only 452/75,473 rows (0.62% of revenue, €166,116) are ghost-flagged in order items, and the monetary amounts on those rows are real transaction data (`quantity`/`unit_price` come from the raw order line, not from the product master) — only the product *reference* is broken. Ghost exclusion is now scoped to COGS/margin only, where it's structurally necessary (no `unit_cost` available).

**Correction (2026-07-18, part 2 — cancelled/returned/refunded):** the first draft of this table didn't filter `order_status` at all. Rewritten to match the project's validated rule.

**Correction (2026-07-18, part 3 — adopted GOV/tiered framework):** replaced the flat measure list with the tiered GOV → Gross Sales Revenue → Net Revenue structure above, after fixing the proposed framework's "recognized revenue" filter (see box above) to avoid reintroducing the rejected Method A over-deduction.

`zero_unit_price_flag` rows left in for now — they contribute €0 to revenue but inflate `Gross Units Sold`. Open question: add a "Units Sold (excl. zero-price)" variant if unit counts feed a per-unit metric.

## Returns — `fact_returns`

| Measure | DAX | Why |
|---|---|---|
| Refund Revenue | `SUM(fact_returns[refund_amount])` | Referenced directly by `Net Revenue` and `Return Rate` in the Sales section above — no separate alias measure. No flag filters — see decision below. |
| Return Count | `CALCULATE(COUNTROWS(fact_returns), fact_returns[ghost_order_flag] = FALSE)` | Operational event count — kept the `ghost_order_flag` exclusion here even though the € measure above doesn't. See decision below for why. |

**Correction (2026-07-18):** `Refund Revenue` originally excluded `ghost_product_flag = TRUE` rows. Checked live: **1,835 of 6,097 return rows (30.1% of refund €, €275,568) are ghost-product-flagged** — far larger than the same flag's impact on order revenue (0.62%). Same reasoning as Gross Revenue applies: `refund_amount` is a real recorded value, only the product reference is broken, so it belongs in the total. Excluding it would have silently understated total refunds by nearly a third.

**Decision (2026-07-18) — `ghost_order_flag` on returns:** originally left excluded pending a decision. Resolved: include it in `Refund Revenue` too. This is a revenue-level (€) measure, and `refund_amount` is a real recorded value whether or not the originating order can be traced — same logic as `ghost_product_flag`. Impact is small either way (60 rows, €4,443, 0.49% of refund €). `Return Count` keeps the exclusion, since "how many verifiable return events happened" (an operational count) is a different question from "how much money was refunded" (a revenue total) — it's still reasonable to want return *events* traceable to a real order even when the refunded amount itself isn't in question.

**Open modeling gap:** an order-count-based return rate ("% of orders that had a return") needs `fact_returns[order_id]` joined to `fact_order_items[order_id]`, but there's no dimension bridging the two fact tables — `dim_order` was excluded from the model. Two options, not yet decided:
1. Use `Return Rate` (defined in the Sales section above) — no cross-fact join needed, €-weighted (probably the better metric anyway).
2. If order-count-based return rate is specifically needed: `CALCULATE(DISTINCTCOUNT(fact_returns[order_id]), TREATAS(VALUES(fact_order_items[order_id]), fact_returns[order_id]))` — works but is an expensive virtual relationship, avoid unless a dashboard page specifically requires it.

## Payments — `fact_payments`

| Measure | DAX | Why |
|---|---|---|
| Realized Revenue (Paid) | `CALCULATE(SUM(fact_payments[payment_amount]), dim_payment[payment_status]="Paid")` | Cash-actually-received number, distinct from order-level Net Revenue. |
| Payment Success Rate | `DIVIDE(CALCULATE(COUNTROWS(fact_payments), dim_payment[payment_status]="Paid"), COUNTROWS(fact_payments))` | |

## Marketing — `fact_marketing_touchpoints`

| Measure | DAX | Why |
|---|---|---|
| Total Touchpoints | `COUNTROWS(fact_marketing_touchpoints)` | |
| Total Clicks | `SUM(fact_marketing_touchpoints[clicked])` | Binary 0/1 columns — sum = count. |
| Total Conversions | `SUM(fact_marketing_touchpoints[converted])` | |
| CTR | `DIVIDE([Total Clicks], [Total Touchpoints])` | |
| Conversion Rate | `DIVIDE([Total Conversions], [Total Clicks])` | Conversion *given a click* — decide vs. "of total touchpoints" depending on dashboard story, label clearly either way. |

## Cross-fact / customer measures — `dim_customer`

| Measure | DAX | Why |
|---|---|---|
| Distinct Customers (Deduped) | `CALCULATE(DISTINCTCOUNT(dim_customer[canonical_customer_key]), dim_customer[customer_key] <> -1)` | Must use `canonical_customer_key`, not `customer_key` — per the documented dedup decision (148 people, 3.5% of base, double-counted otherwise). See modelling decisions doc. |
| Revenue per Customer | `DIVIDE([Net Revenue], [Distinct Customers (Deduped)])` | |
| Repeat Purchase Rate | `DIVIDE(CALCULATE([Distinct Customers (Deduped)], FILTER(VALUES(dim_customer[canonical_customer_key]), CALCULATE(DISTINCTCOUNT(fact_order_items[order_id])) > 1)), [Distinct Customers (Deduped)])` | Nested iterator — fine at ~75k order items, watch performance if row counts grow a lot. |

## Time intelligence — `dim_date`

Before building: mark `dim_date` as a **Date Table** in Power BI (Table tools → Mark as Date Table, using `full_date`), otherwise `SAMEPERIODLASTYEAR`/`DATEADD` misbehave silently.

| Measure | DAX |
|---|---|
| Net Revenue LY | `CALCULATE([Net Revenue], SAMEPERIODLASTYEAR(dim_date[full_date]))` |
| YoY Growth % | `DIVIDE([Net Revenue] - [Net Revenue LY], [Net Revenue LY])` |

**Unchecked:** whether `dim_date` is a contiguous calendar spine (every day, no gaps) or only built from dates present in the source data. If it's not contiguous, time-intelligence functions break silently on missing days — check `dim_date.sql` before relying on the two measures above.

---

## Next steps (pick up here)

1. Confirm `dim_date.sql` generation logic — contiguous spine or not.
2. Decide return-rate approach (revenue-based vs. order-count-based with TREATAS).
3. Decide zero-price handling for `Gross Units Sold`.
4. ~~Decide `ghost_order_flag` treatment on `fact_returns`~~ — **resolved 2026-07-18**: included in `Refund Revenue` (revenue-level measure), still excluded from `Return Count` (operational event count).
5. Sales section now uses the tiered GOV / Gross Sales Revenue / Net Revenue naming, matching `BUSINESS_METADATA.md` exactly except `Net Revenue` (doc calls it "Cash-Based Net Revenue" — see the Naming cross-reference box at the top of the Sales section). Consider updating `BUSINESS_METADATA.md` to rename that one term so there's nothing left to reconcile — currently undecided. That doc is also still marked "should be confirmed with stakeholders," so re-check it hasn't changed before building.
6. Once confirmed, move finalized measures into the actual Power BI model and mark this file's status as "implemented" (or fold the finalized version into `power_bi_modelling_decisions.md` following its Decision/Reason/Business impact/Trade-off structure).
