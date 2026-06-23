# NordHome Retail Analytics — End-to-End Portfolio Project

NordHome is a fictional pan-European online retailer. This project takes intentionally dirty synthetic data, cleans and models it in PostgreSQL, and delivers a star schema data mart and exploratory analysis — demonstrating a full analytics engineering workflow from raw CSV to Power BI dashboard.

---

## Business Scenario

**NordHome** sells home décor, kitchen essentials, beauty products, lifestyle goods, and curated gift sets. Founded in 2018, NordHome operates across ten European markets:

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
| `raw_returns.csv` | Returns | ~6,097 | ~8% of items |
| `raw_marketing_campaigns.csv` | Campaigns | ~12,000 | 14 campaign touchpoints |

**Total: ~166,000 rows** — all intentionally dirty for SQL cleaning practice.

> The `data/raw/` and `data/cleaned/` folders are excluded from version control. Run the generator script (see [Reproducing the Dataset](#reproducing-the-dataset)) to populate them locally.

---

## Data Pipeline

```
scripts/generate_retail_dataset.py   ← synthetic raw CSVs
         ↓
01_data_preparation/                 ← raw schema DDL + data quality findings
         ↓
02_data_cleaning_transformation/     ← staging layer (stg schema, 7 SQL files)
         ↓
validation/                          ← automated SQL assertions and quality checks
         ↓
03_data_modeling/                    ← star schema (6 dimensions, 4 fact tables)
         ↓
04_EDA/ + 05_customer_analysis/      ← Python EDA and customer segmentation
06_product_analysis/ + 07_sales_analysis/
         ↓
dashboards/nordhome_dashboard.pbix   ← Power BI dashboard
```

Each layer has a clear purpose:

| Layer | Purpose |
|-------|---------|
| **Raw** | Original CSV files loaded without changes |
| **Staging** | Clean, standardize, and type-convert every source table |
| **Validation** | SQL assertions for referential integrity and data quality |
| **Data mart** | Kimball star schema — fact and dimension tables for analysis |
| **Reporting** | SQL analysis, Python EDA, and Power BI dashboards |

---

## Star Schema

The data mart follows a Kimball star schema with **4 fact tables** and **6 dimension tables**. All fact tables share `dim_customer` and `dim_date` as conformed dimensions.

**Dimension tables:**

| Table | Grain |
|-------|-------|
| `dim_customer` | One row per customer |
| `dim_product` | One row per product |
| `dim_date` | One calendar day (generated via `GENERATE_SERIES`) |
| `dim_payment` | One row per payment transaction |
| `dim_return_reason` | One row per unique return reason |
| `dim_marketing_campaigns` | One row per `campaign_name + channel` combination |

**Fact tables:**

| Table | Grain |
|-------|-------|
| `fact_order_items` | One row per order line item |
| `fact_payments` | One row per payment transaction |
| `fact_returns` | One row per return event |
| `fact_marketing_touchpoints` | One row per customer-campaign-channel touchpoint |

Key modelling decisions are documented in [03_data_modeling/model_documentation.md](03_data_modeling/model_documentation.md).

---

## Skills Demonstrated

- **SQL data cleaning** — nulls, duplicates, format standardization, referential integrity fixes
- **Data quality assertions** — automated SQL checks at each pipeline stage
- **Kimball star schema design** — fact/dimension separation, conformed dimensions, degenerate dimensions, unknown member pattern
- **Python EDA** — distributions, trends, and segmentation with pandas and matplotlib
- **Customer segmentation** — RFM analysis, cohort analysis, churn risk classification
- **Power BI modelling** — relationships, DAX measures, dashboard layout
- **Data pipeline documentation** — data dictionary, business metadata, model documentation

---

## Folder Structure

```
nordhome_retail_analytics/
├── 01_data_preparation/
│   ├── create_raw_tables.sql          ← raw schema DDL
│   ├── data_quality_checks.sql        ← initial profiling queries
│   ├── data_quality_findings.md       ← findings from raw data inspection
│   └── data_cleaning_decisions.md     ← documented cleaning decisions
│
├── 02_data_cleaning_transformation/
│   ├── stg_customer.sql
│   ├── stg_orders.sql
│   ├── stg_order_items.sql
│   ├── stg_payment.sql
│   ├── stg_product.sql
│   ├── stg_returns.sql
│   ├── stg_marketing_campaigns.sql
│   └── data_validation.md             ← validation checks and results
│
├── 03_data_modeling/
│   ├── 01_dimension_tables/           ← dim_customer, dim_product, dim_date, etc.
│   ├── 02_fact_tables/                ← fact_order_items, fact_payments, etc.
│   ├── model_documentation.md         ← full schema design decisions
│   └── model_validation.md            ← row counts and integrity checks
│
├── 04_EDA/
│   ├── nordhome_eda.ipynb             ← exploratory data analysis
│   ├── base_style.py                  ← shared chart style
│   └── insights.md
│
├── 05_customer_analysis/
│   ├── customer_segmentation.ipynb    ← RFM segmentation
│   ├── cohort_analysis.sql
│   ├── retention_analysis.sql
│   └── insights.md
│
├── 06_product_analysis/
│   └── insights.md
│
├── 07_sales_analysis/
│   ├── sales_forecasting.ipynb
│   └── insights.md
│
├── dashboards/
│   └── nordhome_dashboard.pbix        ← Power BI dashboard
│
├── data/
│   ├── raw/                           ← generated CSVs (not committed)
│   └── cleaned/                       ← cleaned exports (not committed)
│
├── docs/
│   ├── DATA_DICTIONARY.md
│   ├── DATA_PIPELINE.md
│   └── BUSINESS_METADATA.md
│
├── scripts/
│   └── generate_retail_dataset.py     ← synthetic dataset generator
│
└── validation/
    └── data_quality_issues.md
```

---

## Reproducing the Dataset

### Requirements

- Python 3.8+
- PostgreSQL 13+
- pandas, numpy

```bash
pip install pandas numpy
```

### Step 1 — Generate the raw CSV files

```bash
python scripts/generate_retail_dataset.py
# Output written to data/raw/
```

The generator uses `random.seed(42)` and `numpy.random.seed(42)` — output is fully reproducible.

### Step 2 — Set up PostgreSQL

```sql
-- In psql or a SQL client:
CREATE DATABASE nordhome;

-- Connect to the database, then create the schemas:
CREATE SCHEMA raw;
CREATE SCHEMA stg;
CREATE SCHEMA mart;
```

### Step 3 — Load raw tables

Run `01_data_preparation/create_raw_tables.sql` to create the raw schema tables, then load the CSVs using `\COPY` or your SQL client's import tool.

```sql
-- Example for psql:
\COPY raw.customers FROM 'data/raw/raw_customers.csv' WITH (FORMAT csv, HEADER true);
-- Repeat for each table
```

### Step 4 — Run the staging layer

Run each file in `02_data_cleaning_transformation/` (any order):

```
stg_customer.sql
stg_orders.sql
stg_order_items.sql
stg_payment.sql
stg_product.sql
stg_returns.sql
stg_marketing_campaigns.sql
```

### Step 5 — Build the data mart

Run dimension tables first (any order within this step), then fact tables in this specific order:

```
03_data_modeling/01_dimension_tables/   ← run all (any order)

03_data_modeling/02_fact_tables/:
  1. fact_order_items.sql
  2. fact_payments.sql
  3. fact_returns.sql
  4. fact_marketing_touchpoints.sql
```

### Step 6 — Open the Power BI dashboard

Open `dashboards/nordhome_dashboard.pbix` in Power BI Desktop and update the PostgreSQL connection to your local database.

---

## Technologies

| Tool | Use |
|------|-----|
| PostgreSQL 15 | Raw storage, staging, and star schema |
| Python (pandas, numpy, matplotlib) | Dataset generation and EDA |
| Jupyter Notebook | Exploratory analysis and customer segmentation |
| Power BI Desktop | Dashboard and DAX measures |
| Git | Version control |

---

*Dataset generated with Python · pandas · numpy · Seed 42 · NordHome is entirely fictional.*