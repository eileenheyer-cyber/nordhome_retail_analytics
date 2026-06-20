Review `02_data_cleaning_transformation/data_validation.md` for the NordHome Retail Analytics project using the checklist in `docs/prompts/validation_check_prompt.md`.

Check the file against all 5 angles from the prompt:

1. **Coverage** — Are all 7 staging tables covered? Are row counts, business key uniqueness, referential integrity, numeric rules, flagged row counts, and date conversion all present?

2. **SQL correctness** — Schema names use `stg` not `staging`. Column names match the actual stg table definitions. UNION ALL checks are consistently formatted.

3. **Documentation completeness** — Every check has a purpose, a result table with actual numbers, and a plain-English interpretation. Severity levels are assigned where relevant. Modelling decisions are documented.

4. **Duplicate and formatting issues** — No duplicated sections. Section numbers are consistent and in order. No TBD or placeholder values remain.

5. **Portfolio quality** — Findings are explained clearly enough for a recruiter or senior analyst. The final validation summary is consistent with the detail sections.

Return:
- A numbered list of issues found, with the section name
- A suggested fix for each issue
- An overall rating: Needs work / Good / Strong

If $ARGUMENTS is provided, focus the review on that specific section or table.