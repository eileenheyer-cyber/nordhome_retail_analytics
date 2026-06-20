Create a new staging SQL file for: $ARGUMENTS

This project follows the NordHome Retail Analytics pipeline: raw → stg → mart.

Read the quality check findings for this table from `01_data_preparation/data_quality_findings.md` and the cleaning decisions from `01_data_preparation/data_cleaning_decisions.md` before writing any SQL.

Follow the exact CTE structure used in all existing stg files in `02_data_cleaning_transformation/`:

```
source          → SELECT * FROM raw.raw_$ARGUMENTS
cleaned_text    → NULLIF(TRIM(...)) for all text columns
converted_values → cast text to correct types, parse dates, standardize categoricals
flagged_values  → COUNT(*) OVER (PARTITION BY pk) + ROW_NUMBER() for dedup
final           → cleaned columns + all issue flags + CURRENT_TIMESTAMP AS cleaned_at
```

Header comment must include:
- Table name and destination (stg.stg_$ARGUMENTS)
- Raw data findings (row count, duplicates, missing values, key issues)
- Cleaning steps (one bullet per action taken)

Flag naming rules:
- `duplicate_X_flag` — for deduplication
- `ghost_customer_flag` / `ghost_order_flag` — use NOT EXISTS against the raw master table (regular-looking IDs missing from master, NOT LIKE '%GHOST%')
- `ghost_product_flag` — use `COALESCE(product_id LIKE '%GHOST%', FALSE)` (product IDs literally contain PROD-GHOST-*)
- `missing_X_flag` — for NULL values in important columns
- `invalid_X_flag` — for type conversion failures or out-of-range values

Deduplication: always use `ASC NULLS LAST` in ROW_NUMBER() to keep the earliest/first recorded occurrence.

End the file with `SELECT * FROM final;`

Save the file as `02_data_cleaning_transformation/stg_$ARGUMENTS.sql`.