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

### Q1: Which individual products are the top 10 revenue contributors, and which categories do they come from?

**Insight:** Gifts products dominate the top 10 best-sellers by revenue — 5 of the top 10 products belong to the Gifts category, including the single highest earner (Gourmet Hamper XL, €179K). Beauty, Lifestyle, and Home each contribute only 1–2 products to the top 10, with none matching Gifts' concentration at the top of the ranking.

**Evidence:** The top 3 products by revenue are all Gifts (Gourmet Hamper XL €179K, Candle Collection Mini €177K, Candle Collection Organic €165K) before the first non-Gifts product appears (Shower Oil Organic, Beauty, €145K). The lowest of the top 10 (Woven Basket XL, Home) still earns €121K — a fairly tight band across all ten products (top is only 1.48× the tenth).

**Chart:** ![Top 10 products by revenue](figures/top10_products_revenue.png)

**Limitation:** This ranks individual products, not whole categories — Gifts' strong presence here reflects a handful of stand-out SKUs, not proof that Gifts outperforms every other category in total revenue overall.

**Further investigation:** Compare this product-level ranking against total category revenue (not just top-10 presence) to check whether Gifts' strength here is driven by a few stand-out products or reflects genuinely stronger category-wide performance.

---

### Q2: Which product categories have the highest return rate, and where is the financial (refund) impact concentrated?

**Insight:** Kitchen has the highest item return rate at 0.98%, and Gifts ties with Kitchen for the highest total refund value (~€131K each) — despite Gifts having the *lowest* return rate of all categories (0.77%). Return rate and refund value answer different business questions: Gifts is likely higher-priced and higher-volume, so even a below-average return rate still produces above-average refund euros.

**Evidence:** Return rate ranges from 0.77% (Gifts) to 0.98% (Kitchen) — a narrow 0.21 percentage-point band across all 5 categories. Total refund value ranges from €121K (Home) to €131K (Gifts and Kitchen, tied within 0.18%).

**Chart:** ![Return rate and refund value by category](figures/return_rate_and_refund_value_by_category.png)

**Limitation:** All five categories sit within a narrow band on both metrics — the spread is modest relative to typical return-rate variance. Because this dataset is generated, such an evenly clustered pattern may reflect the data generation process rather than a real product-quality signal, and the 0.18% gap between Gifts and Kitchen should not be read as a meaningful ranking.

**Further investigation:** Compute return rate and refund value per unit returned at the product level (not just category) to check whether specific SKUs, rather than whole categories, are driving returns.

---

**Further investigation:** 

---

## 4. Payments

- 
- 
- 

**Further investigation:** 

---

## 5. Returns

- 
- 
- 

**Further investigation:** 

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