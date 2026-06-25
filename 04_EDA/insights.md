# EDA Insights

Key findings from `nordhome_eda.ipynb`. Fill in after running the notebook.

---

## 1. Revenue

### Q1: How has gross revenue trended month by month over time, and what is total revenue across the full period?

**Insight:** Gross and net revenue move closely together month over month. Over the full period (Jan 2021 – Jun 2024), total gross revenue is €24.83M and financial net revenue is €24.24M. The average refund deduction rate is 2.4%, meaning actual cash refunds are small relative to gross revenue. No major structural breaks or prolonged declines are visible in the monthly trend.

**Chart:** [Monthly gross and net revenue line chart](nordhome_eda.ipynb)

---

### Q2: Which countries and sales channels generate the most revenue?

**Insight:** No single country dominates. The top three markets are Denmark (€2.97M, 11.1%), France (€2.75M, 10.3%), and Poland (€2.68M, 10.1%), with the remaining countries spread evenly below. Sales channels are nearly identical in volume: Marketplace 25.5%, Phone 25.0%, Mobile App 24.8%, Website 24.8%. Revenue is structurally well distributed across both dimensions.

**Chart:** [Revenue by country and sales channel](nordhome_eda.ipynb)

---

### Q3: How much do returns, refunds, and cancellations reduce gross revenue — and how does net revenue trend year over year?

**Insight:** Order status impact is stable at around 16–17% of potential order value each year. Cancelled orders account for roughly €0.5–0.6M per year; returned and refunded order value adds another €0.7–0.8M. However, actual cash refunds (from `fact_returns.refund_amount`) total only €0.59M across the full period — a 2.4% deduction rate. The large gap between full order value of Returned/Refunded orders and actual refund amounts confirms that most returns result in only partial refunds.

**Chart:** [Order status impact stacked bar chart](nordhome_eda.ipynb)

---

### Q4: Does NordHome have a quarterly seasonal pattern — does revenue peak at a particular time of year?

**Insight:** No stable seasonal peak exists across complete years. Q3 was the strongest quarter in 2021 and 2023, while Q2 led in 2022. The highest single quarter across the dataset is 2022 Q2 at €1.72M. 2024 is excluded from seasonal comparison as it only covers Q1–Q2. Year-to-year variation is more prominent than any consistent quarterly pattern.

**Chart:** [Quarterly net revenue by year](nordhome_eda.ipynb)

---

## 2. Customers

- 
- 
- 

---

## 3. Products

- 
- 
- 

---

## 4. Payments

- 
- 
- 

---

## 5. Returns

- 
- 
- 

---

## 6. Marketing

- 
- 
- 

---

## Open Questions

Questions raised during EDA that need deeper investigation in the analysis folders.

- 
- 
