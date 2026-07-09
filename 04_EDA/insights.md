# EDA Insights

Key findings from `nordhome_eda.ipynb`. Fill in after running the notebook.

---

## 1. Revenue

### Q1: How has gross revenue trended month by month over time, and what is total revenue across the full period?

**Insight:** Gross and net revenue move closely together month over month. Over the full period (Jan 2021 – Jun 2024), total gross revenue is €24.83M and financial net revenue is €24.24M. The average refund deduction rate is 2.4%, meaning actual cash refunds are small relative to gross revenue. No major structural breaks or prolonged declines are visible in the monthly trend.

**Chart:** ![Monthly gross and net revenue line chart](figures/monthly.png)

---

### Q2: Which countries and sales channels generate the most revenue?

**Insight:** No single country dominates. The top three markets are Denmark (€2.97M, 11.1%), France (€2.75M, 10.3%), and Poland (€2.68M, 10.1%), with the remaining countries spread evenly below. Sales channels are nearly identical in volume: Marketplace 25.5%, Phone 25.0%, Mobile App 24.8%, Website 24.8%. Revenue is structurally well distributed across both dimensions.

**Chart:** ![Revenue by country and sales channel](figures/country.png)

---

### Q3: How much do returns, refunds, and cancellations reduce gross revenue — and how does net revenue trend year over year?

**Insight:** Order status impact is stable at around 16–17% of potential order value each year. Cancelled orders account for roughly €0.5–0.6M per year; returned and refunded order value adds another €0.7–0.8M. However, actual cash refunds (from `fact_returns.refund_amount`) total only €0.59M across the full period — a 2.4% deduction rate. The large gap between full order value of Returned/Refunded orders and actual refund amounts confirms that most returns result in only partial refunds.

**Chart:** ![Order status impact stacked bar chart](figures/status_impact.png)

---

### Q4: Does NordHome have a quarterly seasonal pattern — does revenue peak at a particular time of year?

**Insight:** No stable seasonal peak exists across complete years. Q3 was the strongest quarter in 2021 and 2023, while Q2 led in 2022. The highest single quarter across the dataset is 2022 Q2 at €1.72M. 2024 is excluded from seasonal comparison as it only covers Q1–Q2. Year-to-year variation is more prominent than any consistent quarterly pattern.

**Chart:** ![Quarterly net revenue by year](figures/quarterly.png)

**Further investigation:** 

---

## 2. Customers

### Q1: How are NordHome's customers distributed across markets and countries?

**Insight:** NordHome's customer base is almost uniformly spread across all 10 countries, with each accounting for roughly 9–10% of customers (Norway leads at 10.4%, Austria sits lowest at 9.4% — a spread of under 1 percentage point). At the market level, Nordics (30.3%) and DACH (29.9%) together hold just under 60% of the customer base, with Benelux (19.9%) and Other — France and Poland — (20.0%) splitting the remaining 40% evenly. No single market or country dominates.

**Chart:** ![Customer distribution by market and country](figures/customer_country.png)

---

### Q2: How are NordHome's customers distributed across age groups?

**Insight:** The age mix is remarkably balanced across adults under 70, with each group accounting for 17–20% of known customers (18–29 leads at 19.7%, 40–49 sits lowest at 17.3%). The only clear drop-off is the 70+ group at 9.0% — roughly half the share of any other cohort. Under-18 and unknown age groups are excluded. NordHome's customer base has no dominant age segment among working-age adults.

**Chart:** ![Customer distribution by age group](figures/customer_age.png)

**Further investigation:** Combining demographic and geographic dimensions with purchasing behavior to identify more meaningful customer segments. Purchasing behavior can include order frequency, average order value, total revenue contribution, product category preference, basket size, discount usage, return behavior, and loyalty membership.

---

### Q3: Do loyalty programme members place more orders and spend more per order than non-members?

**Insight:** The loyalty group does not show a clear advantage in total revenue, average order value, or median order value. Loyalty members and non-members generate nearly identical revenue (€13.03M vs €13.18M) and average order value (€1,141 vs €1,137). This suggests that loyalty membership does not meaningfully change order-level spending — loyalty members do not appear to place larger baskets than non-members. The fact that average order value is considerably higher than median order value in both groups also points to a right-skewed distribution: most orders cluster near the median, while a small number of high-value orders pull the average upward.

**Business implication:** Loyalty membership may not be effective at increasing basket size. However, this does not mean the loyalty programme has no value. Its impact may appear in other customer behaviours, such as repeat purchase frequency, retention, churn reduction, or customer lifetime value.

**Recommended next step**

Further analysis should investigate whether loyalty members purchase more frequently, stay active longer, or have higher customer lifetime value compared with non-members.

---

### Q4: What share of customers bought more than once, and how much more do repeat buyers spend on average compared to one-time buyers?

**Insight:** Repeat buyers dominate the customer base — 6,789 customers (85.2%) placed more than one order, versus 1,181 one-time buyers (14.8%). Repeat buyers also generate far more value per customer: €3,117 on average across 3.62 orders, compared to €901 for one-time buyers — a 3.5× difference. Most of NordHome's revenue is driven by customers who return, not by single-purchase acquisition.

**Chart:** ![Repeat vs one-time buyer comparison](figures/buyer_type.png)

**Limitation:** This only measures order count and total spend, not the time between orders — a customer who places two orders in the same week counts as a "repeat buyer" the same as one who returns over years.

**Further investigation:** Look at the time gap between first and second orders to separate genuine repeat behaviour from orders placed close together (e.g. split orders).

---

### Q5: Which age group has the highest average revenue per customer?

**Insight:** The 30–39 age group has the highest average revenue per customer at €2,949, compared with €2,700 for the lowest group (18–29). The spread across all six age groups is under 10% (8.5 percentage points), so age alone is not a strong differentiator of customer value — every group sits in a fairly narrow €2,700–€2,950 band.

**Chart:** ![Average revenue per customer by age group](figures/ltv_by_age_group.png)

**Limitation:** Because this dataset is generated, the narrow, fairly even spread across age groups may reflect the data generation process rather than a real customer behaviour pattern.

**Further investigation:** Combine age group with other dimensions (loyalty status, order frequency, country) to check whether age becomes a stronger differentiator once customers are segmented further.

---

## 3. Products

### Q1: Which product categories drive the most revenue and unit sales?

**Insight:** Category rank shifts depending on whether you measure revenue or volume — average price per unit explains why.

**Finding:** Gifts leads on both revenue (€5,509K) and units sold (115,815) — it's the strongest category outright. But below that, rank order flips between the two metrics: Beauty sells more units (99,153) than Lifestyle (95,875), yet Lifestyle generates more revenue (€5,294K vs €5,206K). Kitchen sits at the bottom on both metrics, despite having the highest revenue-per-unit of any category (~€58/unit vs ~€47–55 elsewhere).

**Chart:** ![Revenue and units sold by category](figures/revenue_units_by_category.png)

**Business interpretation:**
- Gifts is the clear top performer — high volume and the highest revenue, meaning it converts sales into revenue efficiently rather than winning on volume alone.
- Lifestyle vs. Beauty is a classic volume-vs-price trade-off: Beauty moves more units but at a lower average price point, while Lifestyle's roughly 5% higher price per item is enough to overtake Beauty on total revenue despite selling fewer units. This means Beauty's growth strategy should focus on volume/reach (it already has the traffic), while Lifestyle's edge is pricing power, not scale.
- Kitchen is the concerning one. It has the highest price per unit across all categories, but the lowest unit volume and the lowest total revenue. High price alone isn't translating into revenue — this suggests Kitchen may be price-sensitive or under-marketed relative to its price point, since customers aren't buying it at the volume the other categories achieve.

**Why this matters:** Revenue alone would rank these categories Gifts > Home > Lifestyle > Beauty > Kitchen. Units alone would rank them Gifts > Home > Beauty > Lifestyle > Kitchen. Only looking at revenue-per-unit reveals why the middle categories swap — it's not noise, it's a real price/volume trade-off worth acting on differently per category.

**Recommended next step:** For Kitchen specifically, check whether its higher price point correlates with lower return rate or higher return rate (tie back to the return-rate chart) — if Kitchen's high per-unit price is also driving its highest-in-category return rate (0.98%, per the return-rate chart), that's a stronger signal the category is currently overpriced relative to what customers are willing to keep, not just what they're willing to buy.

---

### Q2: Which individual products are the top 10 revenue contributors, and which categories do they come from?

**Insight:** Gifts products dominate the top 10 best-sellers by revenue — 5 of the top 10 products belong to the Gifts category, including the single highest earner (Gourmet Hamper XL, €179K). Beauty, Lifestyle, and Home each contribute only 1–2 products to the top 10, with none matching Gifts' concentration at the top of the ranking.

**Evidence:** The top 3 products by revenue are all Gifts (Gourmet Hamper XL €179K, Candle Collection Mini €177K, Candle Collection Organic €165K) before the first non-Gifts product appears (Shower Oil Organic, Beauty, €145K). The lowest of the top 10 (Woven Basket XL, Home) still earns €121K — a fairly tight band across all ten products (top is only 1.48× the tenth).

**Chart:** ![Top 10 products by revenue](figures/top10_products_revenue.png)

**Limitation:** This ranks individual products, not whole categories — Gifts' strong presence here reflects a handful of stand-out SKUs, not proof that Gifts outperforms every other category in total revenue overall.

**Further investigation:** Compare this product-level ranking against total category revenue (not just top-10 presence) to check whether Gifts' strength here is driven by a few stand-out products or reflects genuinely stronger category-wide performance.

---

### Q3: Which product categories have the highest return rate, and where is the financial (refund) impact concentrated?

**Insight:** Kitchen has the highest item return rate at 0.98%, and Gifts ties with Kitchen for the highest total refund value (~€131K each) — despite Gifts having the *lowest* return rate of all categories (0.77%). Return rate and refund value answer different business questions: Gifts is likely higher-priced and higher-volume, so even a below-average return rate still produces above-average refund euros.

**Evidence:** Return rate ranges from 0.77% (Gifts) to 0.98% (Kitchen) — a narrow 0.21 percentage-point band across all 5 categories. Total refund value ranges from €121K (Home) to €131K (Gifts and Kitchen, tied within 0.18%).

**Chart:** ![Return rate and refund value by category](figures/return_rate_and_refund_value_by_category.png)

**Limitation:** All five categories sit within a narrow band on both metrics — the spread is modest relative to typical return-rate variance. Because this dataset is generated, such an evenly clustered pattern may reflect the data generation process rather than a real product-quality signal, and the 0.18% gap between Gifts and Kitchen should not be read as a meaningful ranking.

**Further investigation:** Compute return rate and refund value per unit returned at the product level (not just category) to check whether specific SKUs, rather than whole categories, are driving returns.

---

### Q4: How does gross margin estimated from catalog list price compare to gross margin realized from actual sales, by product category?

**Insight:** NordHome is selling at a loss across every product category. Realized gross margin — calculated on actual transaction prices net of returns — is negative in every category, ranging from -5% (Lifestyle, Kitchen) to -30% (Beauty). The company's published/catalog pricing implies a healthy ~55% margin, but that margin is never actually being realized at the point of sale.

**Evidence:** Catalog margin sits around 55% uniformly across categories. Realized margin ranges from -5.05% (Lifestyle) and -5.60% (Kitchen) to -10.75% (Home), -24.23% (Gifts), and -30.38% (Beauty).

**Chart:** ![Catalog vs realized gross margin by category](figures/catalog_vs_realized_margin_by_category.png)

**Business interpretation:** The gap between catalog and realized margin points to systemic pricing erosion — the business is pricing products to earn 55% margin on paper, but discounting, promotions, or price overrides are pushing actual sale prices low enough that the company loses money on every unit sold, before even accounting for fixed costs. Beauty and Gifts are the most severely affected (-30% and -24%), suggesting these categories are either the most heavily discounted or the most exposed to promotional/marketing-driven price cuts. Kitchen and Lifestyle are comparatively less damaged but still unprofitable.

**Why this matters:** This isn't a rounding issue — a business cannot sustain negative unit economics at scale. Left unaddressed, every additional order increases realized losses rather than profit, meaning growth in sales volume is actively accelerating losses rather than building revenue.

**Recommended next steps (if this were real):**
- Audit discounting practices by category, especially Beauty and Gifts, to identify whether promotions or price overrides are the driver.
- Cross-reference with the marketing campaigns table — if the negative-margin categories overlap with the most heavily promoted campaigns, that's a strong signal campaigns are being funded by margin, not incremental profit.
- Reassess whether `unit_cost` (cost of goods) is accurate — if COGS assumptions are stale or wrong, the "loss" could be overstated, but if confirmed accurate, pricing strategy needs immediate revision.
- Treat this as a pricing governance issue: catalog price should not be allowed to diverge this far from realized price without an approval/reporting mechanism.

---

## 4. Payments

### Q1: How much of payment value is cleanly collected, and how concentrated is revenue across payment methods?

**Insight:** Payment collection is fragmented across methods, and nearly 1 in 5 euros of payment value isn't cleanly collected.

**Evidence:** Only 70.7% of total payment value lands as "Paid." The remainder is split across Pending (10.1%), Refunded (9.6%), Failed (4.8%), and Partially Refunded (4.7%) — nearly 30% of payment value sits outside a clean, completed transaction. On the method side, no single payment method dominates: Credit Card leads but only at 23.3%, with Debit Card, PayPal, and Bank Transfer essentially tied around 17–18%, and Klarna/BNPL (11.9%) and Apple Pay (11.6%) together accounting for close to a quarter of paid revenue.

**Chart:** ![Payment status and method share](figures/payment_status_and_method_share.png)

**Business interpretation:**
- Failed payments (4.8%) are the most actionable line item — this is revenue lost purely to payment friction (declined cards, timeouts, technical failures), not customer intent to not buy. It's the most direct, quantifiable case for investing in payment retry logic or failure-recovery flows.
- Pending (10.1%) is a cash-flow visibility risk, not necessarily a loss — but at this size, it's material enough that finance shouldn't treat gross order value as equivalent to collected cash when forecasting.
- Refunded + Partially Refunded (~14.3% combined) lines up with the return-rate and margin findings already surfaced above (Kitchen's high return rate, negative realized margin) — this is a third independent signal pointing at the same underlying issue: a meaningful share of revenue doesn't stick.
- The flat payment-method distribution means no method can be deprioritized. Consolidating around "the top payment method" would put roughly three-quarters of paid revenue at risk, since the top four methods are all within a similar range. This also limits negotiating leverage with any single processor, since none of them is indispensable to volume in isolation — but none is safely droppable either.

**Why this matters:** Three separate metrics (returns, margin, payments) are independently converging on the same story — a non-trivial share of revenue that looks "sold" doesn't convert into money the business actually keeps. That consistency across independently-sourced fact tables (`fact_returns`, `fact_order_items`, `fact_payments`) is itself a useful validation signal, not just a business finding — it suggests this isn't noise in one table, but a real pattern reflected across the data model.

**Recommended next step:** Quantify the overlap — are Failed and Pending payments concentrated in specific categories or payment methods (e.g., is Klarna/BNPL disproportionately represented in Failed or Pending)? If so, that narrows the fix to a specific checkout flow rather than a general payments problem.

---

### Q2: Which payment methods carry disproportionate unpaid value risk, relative to how much payment value they process?

**Insight:** Unpaid payment risk is proportional to payment value processed — no payment method is disproportionately risky.

**Evidence:** Comparing each payment method's share of unpaid/pending value against its share of total payment value (both measured in €), the gap stays within **-0.16 to +0.29 percentage points** across all six methods: Klarna/BNPL -0.16, PayPal -0.08, Apple Pay -0.07, Debit Card -0.03, Bank Transfer +0.04, Credit Card +0.29.

**Chart:** ![Unpaid risk vs. payment value share by method](figures/unpaid_risk_vs_volume_by_method.png)

**Business interpretation:** This is a null result on the original hypothesis, and that's a meaningful finding in itself. If payment method choice were driving collection risk, at least one method would show a clear, large deviation from its payment-value share. None do — the largest gap (Credit Card, +0.29pp) is close to negligible. This rules out "payment method" as a driver of unpaid/pending value and redirects the investigation toward other explanatory factors — order value, product category, customer segment, or time-to-payment are more likely candidates than checkout method.

**Why this matters:** Three prior findings (return rate/refund value by category, realized margin, payment status breakdown) all pointed to real, category- or product-level patterns. This analysis shows that not every dimension produces a meaningful pattern — payment method genuinely doesn't. Reporting this negative result alongside the positive ones demonstrates the analysis is following the evidence rather than searching for a story, and it correctly narrows where further investigation should focus.

**Recommended next step:** Re-run the same proportional-deviation logic segmented by order value tier or product category instead of payment method — if unpaid risk concentrates by category (e.g., higher in Kitchen, consistent with its already-elevated return rate) or by order size, that's a stronger and more actionable lead than payment method was.

---

## 5. Returns

### Q1: How have item and revenue return rates trended year over year, and how does H1 2024 compare to previous years?

**Insight:** Both return rates remained relatively stable from 2021 to 2023, then increased clearly in H1 2024.

**Evidence:** Item return rate rose from 8.64% (2023) to 9.74% (H1 2024), +1.10 pp. Revenue return rate rose from 3.65% to 4.02%, +0.37 pp. The item return rate is consistently much higher than the revenue return rate, suggesting returned items are more concentrated in lower-value products rather than the highest-revenue items.

**Chart:** ![Item vs revenue return rate trend](figures/return_rate_trend_item_vs_revenue.png)

**Business interpretation:** Returns became more frequent in 2024, but the revenue impact increased more moderately than the item volume impact. The jump in H1 2024 is a potential warning signal — it may indicate changes in customer expectations, product quality, delivery experience, or product information accuracy. The chart alone does not explain the cause.

Benchmarked externally, NordHome's H1 2024 item return rate (9.74%) sits slightly below the reported German online purchase return rate (~11%), and the revenue return rate (4.02%) sits below the European e-commerce returned-revenue benchmark (~7%). So the absolute level is not unusual — the concern is the *direction* of change after three stable years. Because NordHome is a mixed retail dataset rather than fashion-heavy, these external benchmarks are only rough reference points, not a like-for-like comparison.

**Limitation:** 2024 only includes January–June, so the increase should be interpreted carefully. A full-year comparison or an H1-to-H1 comparison is needed before concluding that 2024 is structurally worse than previous years. External benchmarks also come from different markets/business mixes and are only directionally useful.

**Further investigation:** Investigate which return reasons, product categories, channels, or customer segments contributed most to the 2024 increase. Compare return rates separately by category (Home, Kitchen, Beauty, Gifts, Lifestyle) to benchmark more accurately against a mixed-retail baseline.

---

## 6. Marketing

- 
- 
- 

**Further investigation:** 

---

## Open Questions

Questions raised during EDA that need deeper investigation in the analysis folders.

- 
- 


## limitations

This dataset was generated for analysis practice. Therefore, some distributions, such as customer age groups and country distribution, may have been intentionally created or balanced during the data generation process.

As a result, demographic and geographic patterns should not be interpreted as strong evidence of real market behavior. For example, a balanced age distribution or a specific country share may reflect the design of the synthetic dataset rather than actual customer demand.

These findings are still useful for EDA because they help understand the structure of the dataset and identify potential segmentation dimensions. However, any business conclusion based on age or country distribution should be treated carefully and validated with real customer data.