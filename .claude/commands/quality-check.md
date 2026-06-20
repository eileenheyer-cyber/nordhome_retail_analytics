Run a data quality check on the raw table: $ARGUMENTS

This project lives in the NordHome Retail Analytics PostgreSQL database. Raw tables are in the `raw` schema.

Follow the exact check sequence used in `01_data_preparation/data_quality_checks.sql`:

1. Row count — `SELECT COUNT(*) FROM raw.$ARGUMENTS`
2. Duplicate check — group by the primary key, HAVING COUNT(*) > 1
3. Missing values — COUNT(*) FILTER (WHERE col IS NULL) for every column
4. Value distribution — for categorical columns (status, type, method, channel)
5. Numeric range checks — min, max, negative values, zeros
6. Date format check — identify mixed formats (YYYY-MM-DD, DD/MM/YYYY, MM-DD-YYYY)
7. Referential integrity — check if foreign keys exist in their parent raw table
8. Ghost / invalid references — flag patterns like PROD-GHOST-*, missing from master tables

After running the checks, document the findings in the format used in `01_data_preparation/data_quality_findings.md`:
- A raw data findings table (metric → value)
- A "what needs cleaning" list per issue found
- Add a row to the summary table at the top of data_quality_findings.md

Use `NOT EXISTS` for ghost order/customer references (regular-looking IDs missing from the master table).
Use `LIKE '%GHOST%'` only for ghost product references (product IDs literally contain PROD-GHOST-*).