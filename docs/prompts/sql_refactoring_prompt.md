# Claude Prompt — SQL File Refactoring and Optimization

## Purpose

Use this prompt to review and optimize individual SQL files in the NordHome project.
It covers code quality, naming, structure, correctness, and portfolio readability.

---

## Prompt

```
You are helping me optimize the SQL files in my NordHome Retail Analytics portfolio project.

Please review the following SQL file: [FILE NAME]

This file is part of the [LAYER] layer of the data pipeline:
- Layer: [raw / staging / dimension / fact / analysis]
- Purpose: [brief description of what this file does]

Please check the file from these angles:

1. Correctness
   - Are there any syntax errors, typos, or wrong schema/table names?
   - Are there any logical errors in the cleaning or transformation steps?
   - Do the quality flags correctly reflect the business rules?
   - Are NULL values handled correctly?

2. Code quality
   - Is the CTE structure clear and easy to follow?
   - Are column names descriptive and consistent with the rest of the project?
   - Are there any redundant steps that could be simplified?
   - Is the SQL readable for a reviewer who did not write it?

3. Consistency with the project
   - Does this file follow the same patterns as the other files in the same layer?
   - Are schema names (raw / stg / mart) used correctly?
   - Are quality flags named consistently with the other staging files?
   - Does it use CREATE TABLE AS or INSERT INTO consistently?

4. Portfolio presentation
   - Is the header comment clear and accurate?
   - Are inline comments helpful without over-explaining obvious steps?
   - Would a recruiter or senior analyst be able to understand this file quickly?

Please return:
- A list of issues found (with line numbers if possible)
- Suggested fixes for each issue
- Overall quality rating: Needs work / Good / Strong

Do not change business logic unless you clearly explain why.
Do not rewrite the whole file unless asked — point out what to change and where.
```

---

## When to use

- When starting to optimize a specific SQL file
- After finishing a new SQL file to get a quality check
- When preparing the project for a portfolio review or job application

---

## Example usage

Replace the placeholders before sending:

```
File: 02_data_cleaning_transformation/stg_customer.sql
Layer: Staging / cleaning
Purpose: Cleans the raw customer table and stores the result in stg.stg_customers
```

---

## Notes

- Always read the file first before asking Claude to review it
- Ask Claude to check schema names carefully — a common bug is using `staging` instead of `stg`
- For staging files, pay attention to the quality flags — their names and logic must be consistent
- For dimension files, check that surrogate keys, unknown fallback rows, and column types match the other dimensions