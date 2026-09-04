# Claude Prompt — Data Validation Check

## Purpose

Use this prompt to review validation SQL and validation documentation in the NordHome project.
It ensures that data quality checks are complete, correctly written, and properly documented.

---

## Prompt

```
You are helping me review the data validation layer of my NordHome Retail Analytics project.

Please review the following validation file(s): [FILE NAME(S)]

Context:
- These files are part of the validation layer that runs after staging and before data modeling
- The goal is to confirm that cleaned staging tables are correct and ready for the mart layer
- Validation results are documented in: 02_data_cleaning_transformation/data_validation.md

Please check the validation SQL and documentation from these angles:

1. Coverage
   - Are all 7 staging tables covered by validation checks?
   - Are the following check types included for each table:
     * Row count (does the table exist and contain data?)
     * Business key uniqueness (are the primary keys unique after deduplication?)
     * Referential integrity (can child records join to parent records?)
     * Numeric business rules (no negative quantities, no discounts above 1, etc.)
     * Flagged row counts (how many rows have quality flags?)
     * Date conversion success (are NULL date counts reasonable?)

2. SQL correctness
   - Are schema names correct (stg not staging)?
   - Are column names correct and consistent with the staging table definitions?
   - Are the HAVING and WHERE conditions logically correct?
   - Are UNION ALL checks formatted consistently?

3. Documentation completeness
   - Does each check have a clear purpose description?
   - Are actual result tables included (not just the SQL)?
   - Is the interpretation of each result written in plain English?
   - Are severity levels assigned where relevant (High / Medium / Low)?
   - Are modelling decisions documented based on the validation findings?

4. Duplicate and formatting issues
   - Are any sections duplicated?
   - Are section numbers consistent and in order?
   - Are any sections labeled with "TBD" or placeholder values that should be filled in?

5. Portfolio quality
   - Does the validation document show that you understand data quality beyond just cleaning?
   - Are the findings explained clearly enough for a recruiter or senior analyst to follow?
   - Is the final validation summary table complete and consistent with the detail sections?

Please return:
- A list of issues found (with section name or line number)
- Suggested fixes or additions
- Overall quality rating: Needs work / Good / Strong
```

---

## Validation checks this project should have

| Check type | Tables covered |
|---|---|
| Row counts | All 7 staging tables |
| Business key uniqueness | customers, products, orders, order_items, payments, returns |
| Referential integrity | orders→customers, order_items→orders, order_items→products, payments→orders, returns→orders, returns→products |
| Numeric rules | order_items (quantity, discount), payments (amount), returns (refund_amount) |
| Date conversion | customers, orders, payments, returns, marketing_campaigns, products |
| Quality flag counts | order_items, orders, payments, returns, marketing_campaigns |

---

## Known issues to fix in current validation files

- `data_validation.md` Section 8 (Marketing Campaign Missing Value Check) is duplicated
- `data_validation.md` Validation Summary table at the bottom has "TBD" values — should be filled in or removed
- Section numbering is inconsistent (`## Result 6.` should be `## 6.`)
- `data_quality_checks.sql` mixes raw exploration queries with actual quality assertions — should be cleaned up

---

## When to use

- After creating or modifying staging tables
- After running validation checks against the database
- Before starting the data modeling (mart) layer
- When adding a new table or data source to the project

---

## Notes

- Validation SQL should be read-only (SELECT only) — never DROP or INSERT
- Always document the actual result numbers, not just the SQL
- If a check finds zero issues, still document it — it confirms the cleaning worked
- Validation decisions (what to do with flagged rows) should feed directly into the modeling layer