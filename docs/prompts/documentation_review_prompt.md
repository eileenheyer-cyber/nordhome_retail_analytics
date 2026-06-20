# Claude Prompt — Documentation Review

## Purpose

Use this prompt to review and improve the documentation files in the NordHome project.
It covers completeness, clarity, consistency, and portfolio readability.

---

## Prompt

```
You are helping me review and improve the documentation files in my NordHome Retail Analytics
portfolio project.

Please review the following documentation file: [FILE NAME]

Context:
- This file is located in: [folder path]
- Its purpose is: [brief description]
- The intended audience is: [recruiters / junior analysts / senior reviewers / all]

Please check the file from these angles:

1. Completeness
   - Are there any empty sections, placeholder text, or TBD values that should be filled in?
   - Are all relevant tables, columns, and decisions covered?
   - Are validation results included where they should be?

2. Clarity
   - Is the language clear and easy to understand for the intended audience?
   - Are technical terms explained where needed?
   - Are tables well-formatted and easy to read?

3. Accuracy
   - Does the documentation match what the SQL files actually do?
   - Are table names, column names, and schema names consistent with the code?
   - Are any decisions described but not yet implemented in the SQL?

4. Structure
   - Is the document well-organized with clear headings?
   - Are sections in a logical order?
   - Is there any duplicated content that should be removed?

5. Portfolio quality
   - Would a recruiter reading this document understand the project approach?
   - Does it demonstrate analytical thinking and data engineering awareness?
   - Are modeling decisions explained with clear reasoning, not just described?

Please return:
- A list of issues found (with section names or line numbers)
- Suggested improvements for each issue
- Overall quality rating: Needs work / Good / Strong
```

---

## When to use

- After writing or updating a documentation file
- Before sharing the project with a recruiter or mentor
- When doing a full project review session
- When a document has not been touched in a while and may be out of date

---

## Key documentation files in this project

| File | Purpose |
|---|---|
| `docs/BUSINESS_METADATA.md` | Business definitions, KPIs, rules, and assumptions |
| `docs/DATA_DICTIONARY.md` | Column-level descriptions for all raw tables |
| `docs/DATA_PIPELINE.md` | Overview of the data pipeline layers |
| `02_data_cleaning_transformation/data_cleaning.md` | Cleaning decisions per table |
| `02_data_cleaning_transformation/data_validation.md` | Validation checks and results |
| `03_data_modeling/model_documentation.md` | Star schema design and modelling decisions |
| `04_customer_analysis/insights.md` | Customer analysis findings |
| `05_product_analysis/insights.md` | Product analysis findings |
| `06_sales_analysis/insights.md` | Sales analysis findings |
| `validation/data_quality_issues.md` | Known data quality issues log |

---

## Notes

- Check for duplicate sections — this project has known duplicates in `data_validation.md` and `model_documentation.md`
- Make sure that modelling decisions described in documentation are actually implemented in SQL
- Check that table names in documentation match the actual SQL table names (singular vs plural, underscore vs no underscore)