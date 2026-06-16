# NordHome — Synthetic E-Commerce Analytics Dataset

## Business Scenario

**NordHome** is a fictional pan-European online retailer that sells home décor, kitchen essentials, beauty products, lifestyle goods, and curated gift sets. Founded in 2018, NordHome operates across ten European markets:

| Market | Countries |
|--------|-----------|
| DACH | Germany, Austria, Switzerland |
| Nordics | Sweden, Denmark, Norway |
| Benelux | Netherlands, Belgium |
| Other | France, Poland |

Customers discover NordHome through paid social, influencer marketing, organic search, email campaigns, and affiliate partnerships. Orders are placed via the main website, a mobile app, third-party marketplaces, and telephone. Products ship via Standard, Express, Next-Day, Click & Collect, and Free Shipping tiers.

The business tracks:
- **Sales performance** by country, channel, and product category
- **Customer lifetime value** and loyalty programme membership
- **Marketing campaign ROI** across 14 seasonal campaigns
- **Return rates** and refund costs
- **Churn risk** based on recency of purchase

---

## Dataset Overview

| File | Table | Rows | Notes |
|------|-------|------|-------|
| `raw_customers.csv` | Customers | ~8,364 | Includes duplicates & dirty fields |
| `raw_products.csv` | Products | ~1,090 | Includes discontinued items |
| `raw_orders.csv` | Orders | ~31,465 | Jan 2021 – Jun 2024 |
| `raw_order_items.csv` | Order Items | ~75,473 | Line-level detail |
| `raw_payments.csv` | Payments | ~31,936 | One payment per order |
| `raw_returns.csv` | Returns | ~6,097 | ~8 % of items |
| `raw_marketing_campaigns.csv` | Campaigns | ~12,000 | 14 campaign touchpoints |

**Total: ~166,000 rows** — all intentionally dirty for SQL cleaning practice.

---


## Data Pipeline

The NordHome Retail project follows a layered data pipeline:

Raw CSV files  
→ PostgreSQL raw schema  
→ staging / cleaning layer  
→ validation checks  
→ star schema data mart  
→ SQL & Python analysis  
→ Power BI dashboard

The goal of the pipeline is to transform messy retail data into clean, validated, and analysis-ready tables.

Each layer has a clear purpose:

- **Raw layer:** stores the original CSV files without changes
- **Staging layer:** cleans, standardizes, and converts the data
- **Validation layer:** checks data quality and referential integrity
- **Data mart layer:** builds fact and dimension tables for analysis
- **Reporting layer:** supports SQL analysis, Python EDA, and Power BI dashboards

Detailed documentation can be found in `docs/data_pipeline.md`.

---

## Project Goal

This dataset supports a full end-to-end analytics portfolio project covering:

1. **SQL data cleaning** — fix nulls, duplicates, format inconsistencies, referential integrity
2. **Data quality checks** — automated SQL assertions
3. **Star schema / Power BI modelling** — Fact & Dimension tables
4. **Sales trend analysis** — revenue, AOV, growth rates
5. **Customer segmentation** — RFM analysis
6. **Churn-risk analysis** — Active / At-Risk / Churned classification
7. **Python statistical analysis** — distributions, correlations, hypothesis tests

---

## Reproducing the Dataset

```bash
# Requirements: Python 3.8+, pandas, numpy
pip install pandas numpy

python generate_dataset.py
# Output: data/raw/*.csv
```

The generator uses `random.seed(42)` and `numpy.random.seed(42)` — output is fully reproducible.

*Dataset generated with Python · pandas · numpy · Seed 42 · NordHome is entirely fictional.*