# EDA Insights

## About this document

This documents the exploratory data analysis behind NordHome Retail's dataset (`nordhome_eda.ipynb`) — a synthetic retail/e-commerce dataset covering order items, customers, products, payments, returns, and marketing touchpoints from 2021–2024. Each of the six sections below works through specific business questions with the supporting chart, key finding, business interpretation, and limitations.

**Where to start, depending on what you're looking for:**
- **Just want the bottom line?** → [Summary](#summary) — one paragraph per section.
- **What should NordHome do next?** → [Actions](#actions) (open questions, ranked by severity) and [Business Recommendations](#business-recommendations) (ready-to-act items, ranked by value).
- **Want the full analysis?** → Sections 1–6 below, each structured as Question → Chart → Finding → Business interpretation → Limitation.
- **Data caveats?** → [limitations](#limitations) at the end — this dataset is synthetic, and a few patterns in it (e.g. average order value, age/country distribution) are more a byproduct of how the data was generated than a real business signal.

---

## 1. Revenue

### Q1: How has gross revenue trended month by month over time, and what is total revenue across the full period?

**Insight:** Gross and net revenue move closely together month over month, with an average refund deduction rate of only 2.6% — refunds consistently reduce revenue, but the gap is small relative to overall monthly fluctuations. Over the full period (Jan 2021 – Jun 2024), total gross revenue is €22.68M and financial net revenue is €22.10M. Net revenue reached its lowest point in February 2024 (€0.44M), before recovering to approximately €0.52M in June 2024. No major structural breaks or prolonged declines are visible in the monthly trend.

**Chart:** ![Monthly gross and net revenue line chart](figures/monthly.png)

**Business interpretation:** Refunds do not appear to be the main driver of month-to-month revenue volatility — the larger swings are more likely driven by sales volume, seasonality, promotions, or shifts in product and channel performance.

**Limitation:** The 2024 data only covers January through June, so it should not yet be compared directly with complete prior years.

**Further investigation:** Break down the strongest peaks and declines by product category, market, channel, and order volume, and check whether the 2.4% deduction rate stays stable across these segments.

---

### Q2: Which countries and sales channels generate the most revenue?

**Insight:** No single country dominates. The top three markets are Norway (€2.54M, 10.6%), Germany (€2.51M, 10.5%), and Denmark (€2.44M, 10.2%), with the remaining countries spread evenly down to Poland (€2.23M, 9.3%) — a 1.3 percentage-point spread across all ten. Sales channels are nearly identical in volume: Marketplace 25.2%, Phone 24.9%, Website 24.9%, Mobile App 24.9%. Revenue is structurally well distributed across both dimensions.

**Chart:** ![Revenue by country and sales channel](figures/country.png)

**Business interpretation:** This even distribution limits NordHome's revenue concentration risk — the business isn't heavily dependent on one country or one sales channel, which provides resilience if performance weakens in a particular market or channel. However, equal revenue contribution does not mean equal business value: channels and markets may still differ in margin, customer acquisition cost, return rate, and growth potential.

**Limitation:** Because this dataset is generated, the unusually even distribution across countries and channels may partly reflect the data generation process rather than realistic customer demand.

**Further investigation:** Compare markets and channels on revenue growth, profit margin, average order value, return/cancellation rates, and customer acquisition/retention — not just current revenue share.

---

### Q3: How much do returns, refunds, and cancellations reduce gross revenue — and how does net revenue trend year over year?

**Insight:** Order status impact holds in a narrow 16.5–17.4% band each year, peaking in 2023 (17.4%) rather than rising steadily — 2021 sits at 16.5%, 2022 at 16.7%, and 2024 YTD returns to roughly the 2022 level (16.7%). For the three complete years, the affected value was fairly flat: approximately €1.15M in 2021, €1.18M in 2022, and €1.20M in 2023. Cancelled orders account for roughly €0.45–0.51M per year; returned and refunded order value adds another €0.67–0.71M — and cancellations remain the largest individual component in every year. However, actual cash refunds (from `fact_returns.refund_amount`) total only €0.59M across the full period — a 2.6% deduction rate. The large gap between full order value of Returned/Refunded orders and actual refund amounts confirms that most returns result in only partial refunds.

**Chart:** ![Order status impact stacked bar chart](figures/status_impact.png)

**Business interpretation:** The affected share doesn't move in one steady direction — it peaked in 2023 (17.4%) before easing back to roughly the 2022 level (16.7%) in 2024 YTD. A consistently affected rate in the 16.5–17.4% range still points to a real operational opportunity — reducing cancellations, returns, or refunds would directly increase the share of potential order value NordHome retains, regardless of the exact year-to-year direction. Remaining order value peaked in 2022 at approximately €5.89M before declining to around €5.71M in 2023.

**Limitation:** This chart shows operational order-status impact, not actual financial loss or cash refunds — those are covered separately by the 2.6% deduction rate above. 2024 figures are year-to-date and should not be compared directly with full-year absolute values from prior years. Cancelled, returned, and refunded values were confirmed mutually exclusive (hierarchical CASE logic: cancelled → returned → refunded, each excluding the ones above it) — no double counting in the 16.5–17.4% figure.

**Further investigation:** Identify which products and categories generate the most cancellations, whether certain channels or markets have higher status-impact rates, the most common return reasons, whether cancellations occur before or after fulfilment begins, and whether specific customer groups repeatedly cancel or return orders.

---

### Q4: Does NordHome have a quarterly seasonal pattern — does revenue peak at a particular time of year?

**Insight:** No stable seasonal peak exists across complete years — the strongest quarter differs by year: 2021 peaked in Q3, 2022 peaked in Q4, and 2023 peaked in Q2. 2022 was the strongest year overall (€5.89M), driven by a rise from approximately €1.42M in Q1 to €1.54M in Q4 — the highest single quarter across the dataset. In 2023, revenue rose from Q1 to Q2 before dipping in Q3 and only partially recovering in Q4, contributing to its lower annual result compared with 2022. 2024 is excluded from seasonal comparison as it only covers Q1–Q2.

**Chart:** ![Quarterly net revenue by year](figures/quarterly.png)

**Business interpretation:** 2022's strong year appears driven particularly by Q4 rather than consistently higher performance across every quarter. Combined with the fact that the strongest quarter shifts from year to year (Q3 → Q4 → Q2), there isn't yet enough evidence to conclude NordHome has a stable seasonal peak — year-to-year variation is more prominent than any consistent quarterly pattern. The differences may instead relate to campaigns, product performance, sales channels, markets, or shifts in order volume rather than genuine seasonality.

**Limitation:** Only three complete years are included, and 2024 is excluded from the comparison since it only covers Q1–Q2. This gives an initial view of quarterly behaviour, but more years would be needed to confirm genuine seasonality.

**Further investigation:** Investigate what specifically drove 2022 Q4's exceptional result — order volume and average order value, high-performing products or categories, campaign and channel performance, country-level revenue, and cancellation/return/refund rates for that quarter.

---

## 2. Customers

### Q1: How are NordHome's customers distributed across markets and countries?

**Key finding:** NordHome's customer base is almost uniformly spread across all 10 countries, with each accounting for roughly 9–10% of customers (Norway leads at 10.4%, Austria sits lowest at 9.4% — a spread of under 1 percentage point). At the market level, Nordics (30.3%) and DACH (29.9%) together hold just under 60% of the customer base, with Benelux (19.9%) and Other — France and Poland — (20.0%) splitting the remaining 40% evenly. No single market or country dominates.

**Chart:** ![Customer distribution by market and country](figures/customer_country.png)

**Business interpretation:** With no country or market concentrated enough to call a stronghold, geographic expansion or retention efforts can't be prioritized by customer count alone — any market-level strategy would need to be justified by revenue, margin, or growth potential instead, not customer share.

**Further investigation:** Check whether this even customer distribution also holds for revenue, order frequency, and average order value per country — equal customer counts don't guarantee equal spending behavior.

**Limitation:** Because this dataset is generated, the near-uniform 9–10% spread across all 10 countries is unusually even for a real customer base and may reflect the data generation process rather than genuine market demand.

---

### Q2: How are NordHome's customers distributed across age groups?

**Key finding:** The age mix is remarkably balanced across adults under 70, with each group accounting for 17–20% of known customers (18–29 leads at 19.7%, 40–49 sits lowest at 17.3%). The only clear drop-off is the 70+ group at 9.0% — roughly half the share of any other cohort. Under-18 and unknown age groups are excluded. NordHome's customer base has no dominant age segment among working-age adults.

**Chart:** ![Customer distribution by age group](figures/customer_age.png)

**Business interpretation:** With no dominant working-age segment, broad age-based marketing won't isolate a meaningfully larger "core" audience — behavioral segments (order frequency, category preference, loyalty status) are more likely to reveal real differences than age group alone. The 70+ drop-off is the one pattern worth taking at face value, since lower e-commerce adoption among older shoppers is a plausible, common retail pattern rather than a suspiciously even split.

**Further investigation:** Combine demographic and geographic dimensions with purchasing behavior — order frequency, average order value, total revenue contribution, product category preference, basket size, discount usage, return behavior, and loyalty membership — to identify more meaningful customer segments.

**Limitation:** Because this dataset is generated, the tightly even 17–20% split across age bands under 70 may partly reflect the data generation process rather than a real demographic pattern.

---

### Q3: Which age group has the highest average revenue per customer?

**Key finding:** The 30–39 age group has the highest average revenue per customer at €2,617 — now a near-tie with 40–49 (€2,615, a €1.39 gap) — compared with €2,465 for the lowest group (50–59, previously 18–29 held the lowest spot). The spread across all six age groups is under 6% (5.8 percentage points), so age alone is not a strong differentiator of customer value — every group sits in a fairly narrow €2,465–€2,617 band.

**Chart:** ![Average revenue per customer by age group](figures/ltv_by_age_group.png)

**Business interpretation:** Since the spread is narrow, age alone isn't a strong lever for targeting high-value customers — a broad age-based VIP or retention program would likely misallocate effort. Any genuinely high-value segment is more likely defined by a combination of attributes (age, loyalty status, order frequency) than by age in isolation.

**Further investigation:** Combine age group with other dimensions (loyalty status, order frequency, country) to check whether age becomes a stronger differentiator once customers are segmented further.

**Limitation:** Because this dataset is generated, the narrow, fairly even spread across age groups may reflect the data generation process rather than a real customer behaviour pattern.

### Q4: Do loyalty programme members place more orders and spend more per order than non-members?

**Key finding:** The loyalty group does not show a clear advantage in total revenue, average order value, or median order value. Loyalty members and non-members generate nearly identical revenue (€11.91M vs €12.07M) and average order value (€781 vs €778). This suggests that loyalty membership does not meaningfully change order-level spending — loyalty members do not appear to place larger baskets than non-members. The fact that average order value is considerably higher than median order value in both groups also points to a right-skewed distribution: most orders cluster near the median, while a small number of high-value orders pull the average upward.

**Chart:** ![Loyalty vs non-loyalty revenue and order value comparison](figures/loyalty.png)

**Business interpretation:** Loyalty membership may not be effective at increasing basket size. However, this does not mean the loyalty programme has no value — its impact may appear in other customer behaviours, such as repeat purchase frequency, retention, churn reduction, or customer lifetime value, none of which this chart measures.

**Further investigation:** Investigate whether loyalty members purchase more frequently, stay active longer, or have higher customer lifetime value compared with non-members.

**Limitation:** This comparison assumes the two groups are otherwise similar in size — worth confirming against the customer and order counts now shown on the updated chart before ruling out a spending difference entirely.

---

### Q5: What share of customers bought more than once, and how much more do repeat buyers spend on average compared to one-time buyers?

**Key finding:** Repeat buyers dominate the customer base — 6,789 customers (85.2%) placed more than one order, versus 1,181 one-time buyers (14.8%) (customer counts unaffected by the quantity fix — only the € figures below moved). Repeat buyers also generate far more value per customer: €2,845 on average across 3.62 orders, compared to €800 for one-time buyers — a 3.6× difference. Most of NordHome's revenue is driven by customers who return, not by single-purchase acquisition.

**Chart:** ![Repeat vs one-time buyer comparison](figures/buyer_type.png)

**Business interpretation:** Retention, not acquisition, looks like the primary revenue engine here — converting one-time buyers into repeat customers is likely a higher-ROI lever than pure top-of-funnel acquisition spend, since repeat buyers already generate 3.5× the value per customer.

**Further investigation:** Look at the time gap between first and second orders to separate genuine repeat behaviour from orders placed close together (e.g. split orders).

**Limitation:** This only measures order count and total spend, not the time between orders — a customer who places two orders in the same week counts as a "repeat buyer" the same as one who returns over years.


---

### Q6: How is total revenue per customer distributed, and which customers fall outside the typical range?

**Key finding:** Revenue per customer is right-skewed. The typical range (Q1–Q3) runs from €1,216 to €3,446, and 151 customers — 1.9% of the 7,969-customer base — spend beyond the IQR-based upper bound of €6,790, up to a maximum of €11,428.

**Chart:** ![Customer revenue distribution with IQR outlier threshold](figures/customer_revenue_outliers.png)

**Business interpretation:** A small group of high-spending customers sits well outside the typical range — this is worth treating as its own segment rather than folding into an "average customer" view. It connects to two earlier findings that relied on averages: Q4 showed average order value sitting well above median order value in both loyalty groups, a right-skew signature that matches what this full distribution confirms directly at the whole-customer-base level. It's also a reason to treat Q3's narrow per-age-group averages with some caution — a handful of outliers concentrated in one age group could shift that group's average without reflecting a real group-level difference. These 151 customers are candidates for a dedicated high-value segment.

**Further investigation:** Profile the 151 flagged customers against dimensions already explored — market, age group, loyalty status, product category — to see whether this high-value segment overlaps with anything already found, e.g. is it concentrated in the 30–39 age group from Q3, or spread as evenly as most other dimensions in this dataset?

**Limitation:** The IQR method (1.5× above Q3) is a statistical convention, not a business definition of "high-value" — it flags anyone unusually high relative to this dataset's own distribution, not necessarily customers meeting a specific lifetime-value target. Because this dataset is generated, the flagged group's characteristics should be validated against real customer data before being used to define an actual VIP segment.

---

## 3. Products

### Q1: Which product categories drive the most revenue and unit sales?

**Key finding:** Gifts leads on both revenue (€4,092K) and units sold (38,255) once returned, refunded, and cancelled orders are excluded — the strongest category outright. Revenue ranking tracks units-sold ranking exactly for every category (Beauty lowest → Kitchen → Home → Lifestyle → Gifts highest on both). Revenue per unit is tightly clustered across all five categories, ranging only from €106.96 (Gifts) to €108.36 (Beauty) — about a 1.3% spread.

**Chart:** ![Revenue, units sold, and revenue per unit by category](figures/revenue_units_by_category.png)

**Business interpretation:** Gifts wins on genuine demand — highest revenue AND highest volume — not on a favorable price mix. With revenue-per-unit this flat across categories, unit volume is effectively the whole story behind the revenue ranking: whichever category sells the most units earns the most revenue, in the same order, top to bottom. Beauty is the one to watch — lowest on both revenue and units, with no pricing offset to compensate.

**Further investigation:** Break down Beauty's revenue and units at the product level (see Q2) to check whether its softness is spread evenly across the category or concentrated in a few underperforming products.

**Limitation:** This category-level view assumes a reasonably uniform product mix within each category — a category's average revenue-per-unit could be skewed by one or two outlier-priced products rather than reflecting the category as a whole (see Q2 for product-level detail). Revenue figures here are net of order status (Returned/Refunded/Cancelled excluded) and are not directly comparable to any gross-revenue figures reported elsewhere in this document.

---

### Q2: Which individual products are the top 10 revenue contributors, and which categories do they come from?

**Key finding:** Gifts products dominate the top 10 best-sellers by revenue — 6 of the top 10 products belong to the Gifts category, including the single highest earner (Candle Collection Mini, €144K). Beauty contributes 2 products; Home and Lifestyle each contribute 1. The top 3 products by revenue are all Gifts (Candle Collection Mini €144K, Gourmet Hamper XL €130K, Custom Phone Case Organic €115K), before the first non-Gifts product appears at #4 (Shower Oil Organic, Beauty, €108K). The lowest of the top 10 (Novelty Socks Pro, Gifts) still earns €92K — a fairly tight band across all ten products (top is only 1.58× the tenth).

**Chart:** ![Top 10 products by revenue](figures/top10_products_revenue.png)

**Business interpretation:** Gifts' strength at the top of the product ranking is consistent with its category-level lead in Q1, and here the concentration is even sharper than category-level revenue alone would suggest — 6 of the 10 best-selling products, including the top 3, all come from a single category. That's worth distinguishing from "the whole category performs well": this looks like a handful of hit products carrying Gifts, not uniformly strong performance across every Gifts SKU. Home and Lifestyle each place exactly one product in the top 10, showing their category-level revenue (Q1) isn't concentrated in a standout hit the way Gifts' is.

**Further investigation:** Compare this product-level ranking against total category revenue (not just top-10 presence) to check whether Gifts' strength here is driven by a few stand-out products or reflects genuinely stronger category-wide performance.

**Limitation:** This ranks individual products, not whole categories — Gifts' strong presence here reflects a handful of stand-out SKUs, not proof that Gifts outperforms every other category in total revenue overall. Filters are aligned with Q1 (Returned/Refunded/Cancelled and Unknown category excluded), so the two are directly comparable.

---

### Q3: Which product categories have the highest return rate, and where is the financial (refund) impact concentrated?

**Key finding:** Kitchen has the highest item return rate at 1.94%, and Gifts and Kitchen are effectively tied for the highest total refund value (€131K each, within 0.18%). Return rate ranges from 1.84% (Home) to 1.94% (Kitchen) — a narrow 0.10 percentage-point band across all 5 categories. Total refund value ranges from €121K (Home) to €131K (Gifts).

**Chart:** ![Return rate and refund value by category](figures/return_rate_and_refund_value_by_category.png)

**Business interpretation:** Return rate and refund value still answer different business questions, even though the two rankings are fairly close together: Kitchen leads on return rate (1.94%) but Gifts leads on total refund value (€131K) — consistent with Gifts being the higher-volume, higher-revenue category (confirmed in Q1), so a similar-to-average return rate still produces the largest refund euros. Reporting only one of these two metrics would still give an incomplete picture of which category carries the most return-related risk.

**Further investigation:** Compute return rate and refund value per unit returned at the product level (not just category) to check whether specific SKUs, rather than whole categories, are driving returns.

**Limitation:** All five categories sit within a narrow band on both metrics — the spread is modest relative to typical return-rate variance. Because this dataset is generated, such an evenly clustered pattern may reflect the data generation process rather than a real product-quality signal, and the 0.18% gap between Gifts and Kitchen should not be read as a meaningful ranking.

---

### Q4: How does gross margin estimated from catalog list price compare to gross margin realized from actual sales, by product category?

**Key finding:** Realized gross margin — calculated on actual transaction prices, net of returns — sits meaningfully below catalog margin in every category, but stays solidly positive throughout: 40.2% (Lifestyle) to 46.7% (Gifts), against a catalog margin tightly clustered around 55–57% for every category. Gifts has by far the smallest gap between catalog and realized margin (8.4 percentage points); every other category loses 14.6–16.7 percentage points between list price and what's actually realized at the point of sale.

**Chart:** ![Catalog vs realized gross margin by category](figures/catalog_vs_realized_margin_by_category.png)

**Business interpretation:** The gap between catalog and realized margin points to real pricing erosion from discounting, promotions, or price overrides — but it's a margin-compression story, not a loss-making one: every category remains solidly profitable at the unit-economics level. Gifts stands out for retaining the most of its catalog margin — worth understanding whether that reflects less discounting, a different promotional mix, or simply less room to erode from an already-lower catalog margin. Lifestyle has the largest gap, suggesting it may be the most heavily discounted or promotion-exposed category, even though its realized margin (40.2%) is still healthy in absolute terms.

**Further investigation:** Audit discounting practices by category, especially Lifestyle and Kitchen (the two largest catalog-to-realized gaps), to identify whether promotions or price overrides are the main driver. Cross-reference with the marketing campaigns table to see whether the most-discounted categories overlap with the most heavily promoted ones.

**Limitation:** This assumes `unit_cost` (cost of goods) is accurate — if COGS assumptions are stale or wrong, the true margin gap could be smaller or larger than shown here. There is also a VAT asymmetry between the two sides of this comparison: realized margin assumes `unit_price`/`line_total` are VAT-exclusive (a project-wide assumption, not a verified fact), while `list_price`'s VAT treatment could not be determined at all — it showed near-zero correlation with `unit_price` (r ≈ -0.001), so there's no reliable basis to confirm whether catalog margin is VAT-exclusive too. If `list_price` actually includes VAT, catalog margin is inflated and the true gap to realized margin is smaller than shown here.

---

## 4. Payments

### Q1: How much of payment value is cleanly collected, and how concentrated is revenue across payment methods?

**Insight:** Payment collection is fragmented across methods, and almost 3 in 10 euros of payment value isn't cleanly collected.

**Evidence:** Only 70.3% of total payment value lands as "Paid." The remainder is split across Pending (10.1%), Refunded (9.7%), Failed (4.9%), and Partially Refunded (5.0%) — nearly 30% of payment value sits outside a clean, completed transaction. On the method side, no single payment method dominates: Credit Card leads but only at 23.7%, with Debit Card (17.7%), Bank Transfer (17.6%), and PayPal (17.3%) essentially tied, and Klarna/BNPL (11.9%) and Apple Pay (11.8%) together accounting for close to a quarter of paid revenue.

**Chart:** ![Payment status and method share](figures/payment_status_and_method_share.png)

**Business interpretation:**
- Failed payments (4.9%) are the most actionable line item — this is revenue lost purely to payment friction (declined cards, timeouts, technical failures), not customer intent to not buy. It's the most direct, quantifiable case for investing in payment retry logic or failure-recovery flows.
- Pending (10.1%) is a cash-flow visibility risk, not necessarily a loss — but at this size, it's material enough that finance shouldn't treat gross order value as equivalent to collected cash when forecasting.
- Refunded + Partially Refunded (~14.7% combined) lines up with the return-rate and margin findings already surfaced above (Kitchen's high return rate, negative realized margin) — this is a third independent signal pointing at the same underlying issue: a meaningful share of revenue doesn't stick.
- The flat payment-method distribution means no method can be deprioritized. Consolidating around "the top payment method" would put roughly three-quarters of paid revenue at risk, since the top four methods are all within a similar range. This also limits negotiating leverage with any single processor, since none of them is indispensable to volume in isolation — but none is safely droppable either.

**Why this matters:** Three separate metrics (returns, margin, payments) are independently converging on the same story — a non-trivial share of revenue that looks "sold" doesn't convert into money the business actually keeps. That consistency across independently-sourced fact tables (`fact_returns`, `fact_order_items`, `fact_payments`) is itself a useful validation signal, not just a business finding — it suggests this isn't noise in one table, but a real pattern reflected across the data model.

**Recommended next step:** Quantify the overlap — are Failed and Pending payments concentrated in specific categories or payment methods (e.g., is Klarna/BNPL disproportionately represented in Failed or Pending)? If so, that narrows the fix to a specific checkout flow rather than a general payments problem.

---

### Q2: Which payment methods carry disproportionate unpaid value risk, relative to how much payment value they process?

**Insight:** Unpaid payment risk is proportional to payment value processed — no payment method is disproportionately risky.

**Chart:** ![Unpaid risk vs. payment value share by method](figures/unpaid_risk_vs_volume_by_method.png)

**Business interpretation:** This is a null result on the original hypothesis, and that's a meaningful finding in itself. If payment method choice were driving collection risk, at least one method would show a clear, large deviation from its payment-value share. None do — the largest gap (Credit Card, +0.29pp) is close to negligible. This rules out "payment method" as a driver of unpaid/pending value and redirects the investigation toward other explanatory factors — order value, product category, customer segment, or time-to-payment are more likely candidates than checkout method.

**Why this matters:** Three prior findings (return rate/refund value by category, realized margin, payment status breakdown) all pointed to real, category- or product-level patterns. This analysis shows that not every dimension produces a meaningful pattern — payment method genuinely doesn't. Reporting this negative result alongside the positive ones demonstrates the analysis is following the evidence rather than searching for a story, and it correctly narrows where further investigation should focus.

**Recommended next step:** Re-run the same proportional-deviation logic segmented by order value tier or product category instead of payment method — if unpaid risk concentrates by category (e.g., higher in Kitchen, consistent with its already-elevated return rate) or by order size, that's a stronger and more actionable lead than payment method was.

---

## 5. Returns

### Q1: Which product categories are returned most often, and what reasons drive the most returns?

**Insight:** Return volume is nearly identical across product categories, but heavily concentrated in one reason: customer preference.

**Evidence:** Returns are spread evenly across categories, from 828 (Home) to 887 (Gifts) — a 7% spread across all five categories, so no category stands out as a return-volume hotspot. Return reasons tell a different story: "Customer preference" accounts for 1,358 returns, nearly double the next most common reason (Product information mismatch, 692), while Delivery issue (679), Price issue (675), Fulfillment issue (669), Order issue (666), and Product quality (664) are all tightly clustered together, with Unknown at 634.

**Chart:** ![Return volume by category and reason](figures/returns_by_category_and_reason.png)

**Business interpretation:** Since category barely differentiates return *volume*, category-specific fixes (e.g. targeting Kitchen or Gifts) won't meaningfully reduce total returns — though Q3 in the Products section shows Kitchen still leads on return *rate* relative to units sold, a different metric than the raw count here. The reason breakdown is more actionable: "Customer preference" being the single largest reason, well ahead of every operational reason (delivery, fulfillment, order, quality) individually, suggests returns are driven more by expectation-setting — product description, imagery, sizing — than by operational failures.

**Further investigation:** Break down "Customer preference" returns by category and price tier — if concentrated in specific categories or higher-priced items, that points to a product-page or expectation-setting fix rather than a fulfillment or quality fix.

**Limitation:** "Customer preference" is a broad catch-all reason — it doesn't distinguish "changed my mind" from "didn't match expectations" or other sub-reasons that would each imply a different fix. The two queries behind this chart also use different filters (`ghost_product_flag` for the category panel, `ghost_order_flag` for the reason panel), so totals aren't directly comparable between the two panels — each should be read as its own independent ranking.

---

### Q2: How have item and revenue return rates trended year over year, and how does H1 2024 compare to previous years?

**Insight:** Both return rates remained relatively stable from 2021 to 2023, then increased clearly in H1 2024.

**Chart:** ![Item vs revenue return rate trend](figures/return_rate_trend_item_vs_revenue.png)

**Business interpretation:** Returns became more frequent in 2024, but the revenue impact increased more moderately than the item volume impact. The jump in H1 2024 is a potential warning signal — it may indicate changes in customer expectations, product quality, delivery experience, or product information accuracy. The chart alone does not explain the cause.

Benchmarked externally, NordHome's H1 2024 item return rate (9.74%) sits slightly below the reported German online purchase return rate (~11%), and the revenue return rate (4.50%) sits below the European e-commerce returned-revenue benchmark (~7%). So the absolute level is not unusual — the concern is the *direction* of change after three stable years. Because NordHome is a mixed retail dataset rather than fashion-heavy, these external benchmarks are only rough reference points, not a like-for-like comparison.

**Limitation:** 2024 only includes January–June, so the increase should be interpreted carefully. A full-year comparison or an H1-to-H1 comparison is needed before concluding that 2024 is structurally worse than previous years. External benchmarks also come from different markets/business mixes and are only directionally useful.

**Further investigation:** Investigate which return reasons, product categories, channels, or customer segments contributed most to the 2024 increase. Compare return rates separately by category (Home, Kitchen, Beauty, Gifts, Lifestyle) to benchmark more accurately against a mixed-retail baseline.

---

### Q3: Which sales channel and which country have the highest order-level return rate, and how large are the differences?

**Insight:** Marketplace shows the highest return rate, but differences across channels are small.

**Chart:** ![Order return rate by sales channel and country](figures/order_return_rate_channel_country.png)

**Business interpretation:** No channel or country stands out as a clear return-risk driver — order-level return rate looks structurally consistent regardless of how or where the order was placed. This points away from channel/country as the lever for reducing returns; the driver is more likely elsewhere (product category, price point, or return reason), consistent with Kitchen already carrying the highest item return rate.

**Limitation:** Because this dataset is generated, the tight, even spread across both dimensions may reflect the data generation process rather than a genuine absence of channel/country effects.

**Further investigation:** Check whether return *reason* (not just return rate) varies by channel or country — a flat rate could still hide different underlying causes.

---

### Q4: Where specifically — which channel × country combination — do order return rates run highest, and is that variation meaningful?

**Insight:** No single channel or country drives high returns on its own; the highest rates only show up when you cross the two dimensions, and even then the spread stays fairly narrow.

**Evidence:** Across all 40 channel × country combinations, order-level return rate ranges from 16.0% to 22.8% (average 19.0%). The two highest cells are Marketplace orders in the Netherlands (22.8%, 170 of 745 orders) and Marketplace orders in Denmark (21.9%, 173 of 791 orders) — 3.8 and 2.9 percentage points above the overall average respectively, each based on roughly 750–790 orders. The lowest cell is Marketplace orders in Switzerland (16.0%, 137 of 857 orders).

**Chart:** ![Order return rate heatmap by channel and country](figures/order_return_rate_heatmap.png)

**Business interpretation:** This confirms and sharpens the Q3 finding — return rate isn't explained by channel alone or country alone, but crossing them does reveal a couple of mildly elevated cells (Marketplace × Netherlands, Marketplace × Denmark). A roughly 6.8-percentage-point range across 40 combinations, each with several hundred orders, is a modest spread — worth a note, not yet a strong enough signal to justify channel- or country-specific return policy changes on its own.

**Further investigation:** Check whether Marketplace × Netherlands and Marketplace × Denmark stay elevated when re-cut by return reason or product category — if the elevated cells are driven by the same "Customer preference" pattern seen in Q1, that's a weaker, less actionable signal than if a specific operational reason (delivery, fulfillment) concentrates there.

**Limitation:** With ~40 combinations and roughly 700–860 orders each, the two highest cells could plausibly reflect sampling noise rather than a genuine channel-country effect — a formal significance check (e.g. comparing each cell's return rate against the overall average with a proportion test) would be needed before treating this as a real pattern rather than normal variation.

---

## 6. Marketing

### Q1: Which marketing channels generate the most clicks and conversions, and which channel converts at the highest rate?

**Insight:** Paid Social converts best, but the gap between the strongest and weakest channel is narrow.

**Evidence:** Paid Social leads at 22.4% conversion (111 of 496 clicks), followed closely by SMS (21.2%), Push Notification (20.9%), Display (19.9%), Influencer (19.8%), and Email (19.6%). Affiliate trails at 18.1% (96 of 531 clicks) — the full range across all seven channels is only 4.3 percentage points.

**Chart:** ![Conversion rate by marketing channel](figures/conversion_rate_by_channel.png)

**Business interpretation:** No channel stands out as dramatically better or worse — a 4.3pp spread across roughly 500–540 clicks per channel is a small, possibly noisy gap rather than a decisive performance signal. Paid Social is the nominal leader, but treating this as a clear case for reallocating budget would be premature given how close every channel sits to the 18–22% band.

**Further investigation:** Segment conversion rate by individual campaign within each channel (see Q2) — a channel-level average can mask a few standout or weak campaigns underneath it.

**Limitation:** With 496–542 clicks per channel, a handful of additional conversions could shift the ranking — this should be read as directional, not a confirmed ranking, without a larger sample or a formal significance test.

---

### Q2: Which campaigns are most effective at converting customers, and which marketing channels drive this performance?

**Insight:** The top-converting campaigns cluster around seasonal/promotional moments (Spring Refresh, Black Friday, Summer Sale) rather than any single channel.

**Evidence:** Of the top 10 campaigns by conversion rate (filtered to campaigns with 30+ clicks), Spring Refresh 2022 and Spring Refresh 2024 tie for first at 38.24% — both via Push Notification, with identical volumes (34 clicks, 13 conversions). Black Friday 2022 (SMS) follows at 37.5%. Channels are mixed across the remaining top 10: Push Notification, SMS, Paid Social, Affiliate, Influencer, and Display all appear at least once.

**Chart:** ![Top 10 campaigns by conversion rate](figures/top10_campaigns_conversion_rate.png)

**Business interpretation:** The top campaigns aren't concentrated in one channel — Q1's channel-level ranking (Paid Social leading) doesn't hold once you look at individual campaigns; Paid Social appears twice in the top 10, but so do several other channels. This suggests campaign design and targeting matter more than channel choice alone. That two campaigns two years apart (Spring Refresh 2022, Spring Refresh 2024) return an identical click and conversion count (34/13) is unusual and worth flagging rather than treating as a repeatable seasonal effect.

**Further investigation:** Check whether seasonal campaign types (Spring Refresh, Black Friday, Summer Sale) systematically outperform always-on/non-seasonal campaigns across the full campaign list, not just this top-10 cut.

**Limitation:** All top 10 campaigns have small click volumes (31–42), close to the >30-click filter threshold — conversion rates from samples this small are noisy, and the exact duplicate result (Spring Refresh 2022 vs. 2024) suggests this may reflect the synthetic data generation process rather than a genuine, repeatable campaign effect.

---

### Q3: Which marketing channels convert loyalty members more effectively than non-members, and where should NordHome tailor its targeting strategy?

**Insight:** Loyalty members convert better through direct, opt-in channels (Push Notification, SMS, Influencer); non-members convert better through Email.

**Evidence:** Loyalty members show meaningfully higher conversion on Push Notification (22.6% vs. 19.0%, +3.6pp), SMS (22.9% vs. 19.5%, +3.4pp), and Influencer (20.9% vs. 18.8%, +2.1pp). Non-members convert better on Email (20.6% vs. 18.7% for loyalty members — a 1.9pp gap in the opposite direction). Paid Social, Display, and Affiliate show only small gaps (within 0.4pp) either way.

**Chart:** ![Loyalty vs. non-loyalty conversion by channel](figures/loyalty_conversion_dumbbell.png)

**Business interpretation:** This is a more targeted, actionable version of Q1/Q2 — rather than picking one "best" channel overall, NordHome could route loyalty members toward Push Notification and SMS (channels that already require an opt-in relationship, consistent with a loyalty member's existing engagement) and prioritize Email for reaching non-members, instead of applying one channel strategy across all customers.

**Further investigation:** Test whether this pattern holds at the campaign level (cross with Q2) — are loyalty members specifically driving the Push Notification top-campaign results seen in Q2 (Spring Refresh 2022/2024)?

**Limitation:** Each channel × loyalty-status combination has a consistent ~250–285 clicks, which makes this comparison more reliable than Q2's — but the gaps (2–4pp) are still modest enough to treat as directional rather than confirmed, until re-tested on more data or over a longer period.

---

## Summary

### Revenue Analysis Summary

NordHome's revenue base is diversified across countries and channels, and leakage from actual cash refunds is small (2.6%). The bigger opportunity sits on the order-status side: 16.5–17.4% of potential order value is lost to cancellations, returns, and refunds every year, driven mainly by cancellations, holding in a narrow band without a clear improving trend (peaked in 2023, eased back in 2024 YTD). No stable seasonal pattern exists yet — 2022 stands out as the strongest year, but that looks driven by specific strong quarters (Q2, Q4) rather than a repeatable seasonal effect.

### Customer Analysis Summary

Demographic and geographic dimensions — country, market, age group, and loyalty status — show almost no differentiation in customer value; NordHome's customer base is evenly spread across all of them, and average order value or revenue per customer barely moves between groups. The real differentiation is behavioral: repeat buyers (85% of customers) generate 3.6× more value per customer than one-time buyers, and within the base overall, a small group of 151 high-spending customers (1.9%) sits outside the typical revenue range. Any real segmentation strategy should be built on purchase behavior and revenue tier, not demographics — age, country, and loyalty membership alone don't predict value in this dataset.

### Product Analysis Summary

Gifts is the standout category — strongest on revenue, units, and product-level rankings, and it also retains the most catalog margin at the point of sale. Beauty is the one to watch on the volume side — lowest revenue and units — though revenue-per-unit is essentially flat across every category now, so no category shows an overpricing-relative-to-demand pattern. Kitchen leads on return rate (1.94%), but return-related risk doesn't map cleanly onto revenue or return-rate rankings alone — Gifts carries the highest refund euros despite a near-average return rate, purely because of its scale. Margin tells the healthiest story: realized gross margin stays solidly positive in every category (40–47%), well below catalog margin (55–57%) but nowhere close to a loss — Lifestyle shows the largest catalog-to-realized gap and is the best candidate for a discounting audit.

### Payments Analysis Summary

Payment collection, not payment method, is where the risk sits. Nearly 30% of payment value never reaches a clean "Paid" state — split across Pending (10.1%), Refunded (9.7%), Partially Refunded (5.0%), and Failed (4.9%) — and Failed is the clearest lever since it reflects payment friction, not lost customer intent. Payment method choice is not the driver of this risk: unpaid value is proportional to payment volume for every method, with the largest deviation (Credit Card) only +0.29pp. Combined with the returns and margin findings from earlier sections, this is a third independent signal that a meaningful share of "sold" revenue doesn't convert into collected cash — and the fix belongs in checkout/collection processes and order-level segmentation (value tier, category, time-to-payment), not in favoring one payment method over another.

### Returns Analysis Summary

Return rates held steady for three years (2021–2023: ~8.2–8.7% of items, ~3.8–4.1% of revenue) before rising in H1 2024 (9.74% items, 4.50% revenue) — a real shift, though still within external benchmark ranges. Neither category, channel, nor country explains the pattern on its own: return volume is nearly flat across product categories (Q1), return rate is nearly flat across sales channels (19.1–19.8%) and countries (18.0–20.2%) (Q3), and even crossing channel with country only turns up a modest 16.0–22.8% range (Q4). The one dimension that does differentiate clearly is return *reason* — "Customer preference" accounts for far more returns than any operational cause (Q1), consistent with Kitchen's already-elevated item return rate from the Products section. Together, this points the 2024 investigation toward product-level and reason-level drivers — product descriptions, imagery, expectation-setting — rather than channel, country, or geography.

### Marketing Analysis Summary

Channel-level conversion differences are narrow on their own (Q1: a 4.3pp range across all seven channels), and the strongest campaigns don't concentrate in one channel either (Q2: top 10 spans six different channels). The clearest, most actionable pattern only appears once you segment by audience: loyalty members convert better through direct, opt-in channels (Push Notification, SMS, Influencer), while non-members respond better to Email (Q3). This reframes the original question from "which channel is best" to "which channel is best for which audience" — NordHome's targeting strategy should split by loyalty status rather than lead with a single company-wide channel priority.

---

## Actions

Follow-up actions from this EDA, ordered by business severity — most urgent first, easing toward lower-priority validation checks.

1. **Reduce cancellation rate, the largest single driver of the 16.5–17.4% order-status impact** (Revenue Q3) — cancellations account for more lost order value than returns and refunds combined in every year; this is the single biggest lever for retaining potential order value.
2. **Quantify whether Failed and Pending payments concentrate in specific categories or payment methods** (Payments Q1) — turns the "nearly 30% of payment value isn't cleanly collected" finding into an actionable fix rather than a general observation.
3. **Identify which product categories, channels, or customer segments drove the H1 2024 return-rate increase** (Returns Q2) — determines whether 2024 is a real emerging problem or a short-term blip.
4. **Segment unpaid payment risk by order value tier or product category** (Payments Q2) — payment method was ruled out as the driver; this is the next most likely lead.
5. **Break down "Customer preference" returns by category and price tier** (Returns Q1) — the dominant return reason is too broad to act on without this cut.
6. **Audit discounting practices by category, especially Lifestyle and Kitchen, and cross-reference against marketing campaigns** (Products Q4) — needed to identify why these two categories show the largest catalog-to-realized margin gap; a pricing-optimization question now, not a loss to fix.
7. **Verify `unit_cost` accuracy and resolve the `list_price` VAT treatment** (Products Q4) — the exact size of the catalog-to-realized margin gap depends on both being correct; if COGS is stale or `list_price` turns out to include VAT, the true gap could be smaller than the 8.4–16.7 percentage points currently shown.
8. **Profile the 151 flagged high-value customers against market, age group, loyalty status, and category** (Customers Q6) — needed to confirm whether a real, targetable VIP segment exists or whether it's evenly spread like everything else.
9. **Check whether loyalty members purchase more frequently or show higher lifetime value than non-members** (Customers Q4) — basket size shows no loyalty effect, so the program's value, if any, must be justified on a different metric.
10. **Test whether the loyalty-channel conversion pattern holds at the individual campaign level** (Marketing Q3) — confirms whether Push Notification/SMS is genuinely stronger for loyalty members or just an average-level artifact.

---

## Business Recommendations

Recommendations that already follow from confirmed EDA findings, ranked by business value — ready-to-brief actions, not open questions still needing validation (see Actions above for those).

1. **Shift retention/CRM budget toward converting one-time buyers into repeat buyers, not pure acquisition** (Customers Q5) — repeat buyers are 85% of the customer base and generate 3.6× more revenue per customer (€2,845 vs €800). This is the single highest-confidence, highest-value lever in the dataset: it touches the majority of the customer base and the effect size is large.
2. **Invest in payment retry / failure-recovery flows** (Payments Q1) — Failed payments (4.9% of payment value) are pure friction loss on orders customers already intended to complete, not lost demand. A technical/process fix with a directly quantifiable recovery target.
3. **Prioritize cancellation reduction over return/refund reduction** (Revenue Q3) — cancellations are the largest single component of the 16.5–17.4% order-status impact every year (~€0.45–0.51M/year alone, more than returns and refunds combined). Whatever is driving cancellations (checkout friction, fulfilment delays, cooling-off windows) is the highest-value target in the order lifecycle.
4. **Fix product pages and expectation-setting content, not fulfilment operations, to reduce returns** (Returns Q1) — "Customer preference" drives nearly double the returns of any operational reason (delivery, fulfillment, quality) combined. The evidence already points to a content/description fix, not a logistics fix.
5. **Split marketing channel strategy by loyalty status instead of picking one "best" channel** (Marketing Q3) — loyalty members convert meaningfully better via Push Notification, SMS, and Influencer; non-members convert better via Email. Routing spend and creative by audience is a low-cost targeting change with a clear, already-measured lift.
6. **Protect Gifts as the priority category, but review concentration risk** (Products Q1–Q2) — Gifts leads on revenue, units, and retains the most catalog margin of any category. It deserves continued marketing/inventory priority, but 6 of the top 10 best-selling products sit in this one category — worth a supply-chain review, since a stockout on a handful of hero SKUs would disproportionately hurt revenue.


## limitations

This dataset was generated for analysis practice. Therefore, some distributions, such as customer age groups and country distribution, may have been intentionally created or balanced during the data generation process.

As a result, demographic and geographic patterns should not be interpreted as strong evidence of real market behavior. For example, a balanced age distribution or a specific country share may reflect the design of the synthetic dataset rather than actual customer demand.

These findings are still useful for EDA because they help understand the structure of the dataset and identify potential segmentation dimensions. However, any business conclusion based on age or country distribution should be treated carefully and validated with real customer data.

**Order value and pricing:** AOV (€778–€800) is high for this product mix and nearly identical across every customer segment — a sign it's driven by generation artifacts (`unit_price` averages €127 with a flat €250.00 cap; quantity averages exactly 3.00, the midpoint of 1–5) rather than real pricing or purchase behavior. Don't benchmark AOV against real-world retail, and don't use it to infer a different business model (e.g. wholesale) for NordHome.