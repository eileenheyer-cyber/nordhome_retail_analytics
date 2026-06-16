## Data Pipeline Overview

The NordHome Retail data pipeline follows a layered structure:

1. **Raw Layer**
   - Stores the original CSV data without transformation.
   - Purpose: preserve the source data for traceability.

2. **Staging / Cleaning Layer**
   - Cleans and standardizes each table.
   - Handles missing values, inconsistent formats, invalid data types, duplicate records, and business-rule issues.
   - Adds data quality flags where records should be kept but treated carefully.

3. **Validation Layer**
   - Checks data quality after cleaning.
   - Focuses on referential integrity, duplicate keys, invalid dates, missing foreign keys, and unmatched records.
   - Documents remaining issues and cleaning decisions.

4. **Data Mart Layer**
   - Builds a star schema for analysis.
   - Uses fact tables for business events such as orders, order items, payments, and returns.
   - Uses dimension tables for descriptive information such as customers, products, dates, and stores.

5. **Analysis & Reporting Layer**
   - Uses SQL and Python for exploratory analysis.
   - Uses Power BI to create dashboards and business insights.


The data pipeline transforms raw retail CSV files into cleaned, validated, and analysis-ready tables. The process includes raw data loading, staging and cleaning, data quality validation, star schema modelling, and final analysis in SQL, Python, and Power BI.
