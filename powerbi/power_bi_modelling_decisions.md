# Power BI Modelling Decisions

This file documents decisions made specifically while loading the `mart` tables into Power BI. These are Power BI-model-only decisions — the underlying Postgres `mart` schema is unaffected unless explicitly stated.

For the source star schema design, see `03_data_modeling/model_documentation.md`. For column-level type reference, see `docs/MART_SCHEMA_REFERENCE.md`.

---

## Export note: boolean columns cast to true/false text

### Decision
`powerbi/export_mart_to_csv.sql` casts every `boolean` column (e.g. `ghost_product_flag`, `loyalty_member`, `is_weekend`) to the text values `'true'` / `'false'` instead of exporting them as-is.

### Reason
Postgres's `COPY ... CSV` writes booleans as `t` / `f`. Power BI's automatic type detection does not recognize `t`/`f` as Boolean and silently imports the column as Text instead, which breaks any visual or measure expecting a true Boolean field.

### Business impact
All flag columns import correctly as Boolean type in Power BI with no manual Power Query fixup needed per column, per table.

### Trade-off or limitation
If new boolean columns are added to any mart table in the future, `export_mart_to_csv.sql` must be updated to add the same `CASE WHEN ... THEN 'true' ELSE 'false' END` cast, or the new column will re-introduce the same t/f import issue.

---

## Modelling decision: dim_order excluded from export

### Decision
`mart.dim_order` (31,001 rows) is not exported to CSV and not part of the Power BI model.

### Reason
`dim_order` was removed from the star schema design (`model_documentation.md` §4.1) — order attributes were denormalized onto the fact tables instead. The table still physically exists in Postgres as a stale leftover from before that decision, has no build script in `03_data_modeling/`, and no fact table has a foreign key to it (confirmed via `information_schema.columns` on `fact_order_items`).

### Business impact
None — the table is unused. Order-level attributes (`order_status`, `country`, `sales_channel`, `shipping_method`) are already available directly on `fact_order_items`, `fact_payments`, and `fact_returns`.

### Trade-off or limitation
`mart.dim_order` still exists in Postgres, untouched. It was not dropped — only excluded from this export — since removing it from the database was out of scope for this decision.

---

## Modelling decision: created_at columns excluded (recommended)

### Decision
`created_at` audit timestamp columns (present on every mart table) should be excluded from the Power BI model or left unloaded.

### Reason
These are row-insert audit timestamps from the ETL process, not business dates. They carry no analytical value and add clutter to the field list.

### Business impact
None on any business question.

### Trade-off or limitation
If ETL/load-timing needs to be audited later, these columns are still present in the source CSVs and Postgres tables — they can be re-added at any time.

---

## Modelling decision: dim_customer data-quality flags excluded

### Decision
`missing_email_flag`, `missing_phone_flag`, and `missing_registration_date_flag` are excluded from the Power BI model.

### Reason
These are data-completeness indicators computed in staging, not business dimensions. None of the dashboard's business questions (revenue, AOV, segmentation, loyalty comparison) depend on them.

### Business impact
None on core business measures. A future "data completeness" reporting page would need these re-imported.

### Trade-off or limitation
Fully reversible — the columns remain in `mart.dim_customer` in Postgres and in `docs/DATA_DICTIONARY.md` / `docs/MART_SCHEMA_REFERENCE.md`. Only the Power BI model omits them.

---

## Modelling decision: canonical_customer_key and duplicate_customer_flag kept in Power BI model

### Decision
Both `canonical_customer_key` and `duplicate_customer_flag` are imported into the Power BI model, reversing an earlier decision to exclude them.

### Reason
Duplicate customer identities affect 148 people (296 rows, ~3.5% of the 8,365-row customer base), and 91% of those pairs (135/148) placed real orders under *both* customer keys (`model_documentation.md` §4.8). Excluding `canonical_customer_key` from the dashboard would have silently reintroduced the exact problem the mart-level fix was built to solve — any customer-count or CLV visual would look precise while actually running ~3.5% high, with no visible caveat. Chose accuracy and transparency over the smaller/simpler model.

### Business impact
Any measure that **counts or divides by number of customers** must group by `canonical_customer_key`, not `customer_key`:
- `Number of Customers` / `Active Customers`
- `Customers by Country` / `Customers by Segment` (loyalty, age group)
- `Revenue per Customer` / CLV-style measures
- `Repeat Purchase Rate`

Measures that only sum revenue, orders, or events — `AOV`, `Net Revenue`, `Gross Revenue`, `Return Rate`, `Revenue by Country/Channel/Loyalty Segment` — are unaffected either way, since customer identity never enters those calculations.

### Trade-off or limitation
None functionally — this restores full consistency with the documented SQL-level fix. The only cost is one extra join key to remember when building customer-count measures (mitigated by naming those DAX measures clearly, e.g. `Distinct Customers (Deduped)`, so nobody reverts to `customer_key` by habit).

---

## Modelling decision: dim_product columns excluded from Power BI model

### Decision
`launch_date`, `list_price`, `price_issue_flag`, `product_quality_status`, and `created_at` are excluded from the Power BI model. `product_key`, `product_id`, `product_name`, `category`, `subcategory`, `brand`, `unit_cost`, and `discontinued_flag` are kept.

### Reason
- `launch_date` — not tied to any of the four documented product business questions (`model_documentation.md` §7) unless doing product-lifecycle analysis, which isn't in scope for this dashboard.
- `price_issue_flag`, `product_quality_status` — data-quality indicators, not business dimensions. `product_quality_status` is derived from the same ghost-detection logic already exposed as `ghost_product_flag` on `fact_order_items`/`fact_returns` (confirmed in `dim_product.sql`), so it's redundant for revenue-exclusion purposes on the main dashboard.
- `created_at` — audit-only, same rule applied to every table in this model.
- `list_price` — initially kept, then reversed to excluded. See reasoning below; this is a case where "reversible so why not keep it" was the wrong instinct.

### Business impact
`category`, `subcategory`, `brand`, `unit_cost`, and `discontinued_flag` support the core product business questions (revenue by category, margin, active vs. discontinued catalog). None of them depend on `list_price`.

### Trade-off or limitation
**Why `list_price` was excluded, not just cautioned about:** per `docs/business_rules/BUSINESS_METADATA.md`, `list_price` and `unit_price` were rigorously tested and show **effectively zero correlation** across 74,783 matched order lines (r ≈ -0.001), with differences up to +3,000% — far beyond anything a VAT rate, discount, or consistent markup could explain. The two fields are statistically independent in this dataset.

The deciding factor over simply keeping-with-a-warning: `list_price` sits directly next to `unit_price` in the Fields pane, and the failure mode of misusing it is silent — a "% discount from list" or margin chart built on it would look completely normal while actually visualizing noise from the data generation process, not a real business pattern. That risk was judged to outweigh the narrow legitimate uses (plain catalog display, an explicitly-labeled hypothetical "catalog margin," or a scatter plot surfacing the zero-correlation finding itself as a documented data-quality observation) — none of which were concretely planned for this dashboard.

Fully reversible: the column remains in `mart.dim_product` in Postgres and in `docs/business_rules/BUSINESS_METADATA.md`. Re-import it only if one of the three narrow legitimate uses above becomes a concrete, deliberate deliverable — not as a default "might as well" inclusion.

Any margin measure must use `unit_price − unit_cost`, never `list_price − unit_cost`.

Also worth remembering: the `product_key = -1` unknown-product fallback row has `price_issue_flag = TRUE` hardcoded in `dim_product.sql` — not a real flagged product, just the fallback row's default. Since `price_issue_flag` is excluded from this model, this doesn't surface as an issue here, but is worth knowing if the column is ever re-imported.

---

## Modelling decision: fact_marketing_touchpoints columns

### Decision

| Column | Recommendation | Why |
|---|---|---|
| `customer_key`, `campaign_key`, `campaign_date_key` | Keep | Relationship keys — needed for every marketing business question (clicks/conversions by campaign, channel, over time) |
| `clicked`, `converted` | Keep | The core measures — CTR and conversion rate are built directly from these |
| `ghost_customer_flag` | Exclude | Checked live: 0 of 12,000 rows are flagged — no ghost customers currently present, so the column adds no value |
| `converted_without_click_flag` | Exclude | Checked live: 0 of 12,000 rows are flagged — this data-quality issue doesn't occur in this dataset, so the column adds no value |
| `fact_touchpoint_key`, `marketing_touchpoint_id` | Keep, hidden from report view | PK and degenerate ID — needed for uniqueness/drill-through, never dragged into a visual directly |
| `created_at` | Exclude | Audit-only, same rule as every other table |

### Reason
Both flags were checked against the live data before deciding, rather than excluded on principle — see limitation below.

### Business impact
Supports all three documented marketing business questions (`model_documentation.md` §7): clicks/conversions by campaign, conversion rate by channel, and (via `customer_key`) cross-fact attribution of revenue to customers who converted on a campaign (§6).

### Trade-off or limitation
Checked live (2026-07-15): 0 of 12,000 rows have `ghost_customer_flag = true`, and 0 rows have `converted_without_click_flag = true` (confirmed independently against the raw condition `converted = 1 AND clicked = 0`). Both are exclusions of convenience, not principle — if the source data is ever regenerated or refreshed, re-check both counts before assuming it's still safe to leave them out.
