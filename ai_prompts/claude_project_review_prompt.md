# Claude Prompt — Full Project Review

## Purpose

Use this prompt to get a structured review of the entire NordHome Retail Analytics project.
It covers folder structure, SQL workflow, data modelling, documentation, reproducibility, and portfolio quality.

---

## Prompt

```
You are helping me optimize my NordHome Retail data analytics portfolio project.

Please go through the whole project folder and review the current structure, SQL files,
documentation files, notebooks, and README.

Important: Do not change any files yet. First give me a structured review and suggestions only.

Please check the project from these perspectives:

1. Folder structure
   - Is the current folder structure clear and professional?
   - Are SQL files, documentation, validation checks, notebooks, and data dictionary files organized logically?
   - Suggest a better structure if needed.

2. SQL workflow
   - Check whether the SQL files follow a clear order from raw data to staging/cleaning to mart tables.
   - Identify duplicated SQL patterns.
   - Suggest where code could be simplified, split, renamed, or better commented.
   - Do not change business logic unless you clearly explain why.

3. Data modelling
   - Review whether dimension tables and fact tables are placed and named consistently.
   - Check whether table grain is clear.
   - Check whether surrogate keys, fallback rows, unknown rows, and quality flags are used consistently.
   - Point out anything that could confuse a recruiter or reviewer.

4. Documentation
   - Check whether modelling decisions are documented clearly.
   - Check whether validation results are documented in the right place.
   - Suggest which documentation files are missing or should be improved.
   - Help me make the project understandable for a junior data analyst portfolio.

5. Reproducibility
   - Check whether another person could run this project from the README.
   - Suggest improvements for setup instructions, execution order, database schema creation, and dependencies.

6. Portfolio quality
   - Tell me what parts already look strong.
   - Tell me what looks messy, inconsistent, or unfinished.
   - Prioritize improvements by importance: high, medium, low.

Please return your answer in this structure:

## Overall impression
## Strengths
## Main issues
## Suggested folder structure
## SQL workflow improvements
## Documentation improvements
## Reproducibility improvements
## Portfolio/recruiter perspective
## Priority action list

Remember: Do not edit files yet. Only analyze and suggest improvements.
```

---

## When to use

- At the start of a new working session to get a fresh perspective
- After completing a major section (e.g., finishing all staging tables)
- Before sharing the project with a recruiter or mentor
- After a long break to re-orient on what still needs to be done

---

## Notes

- Scan all files before responding — do not skip folders
- Ask Claude to read all SQL files, markdown docs, and the README before giving feedback
- This prompt works best when the project folder is clean and up to date