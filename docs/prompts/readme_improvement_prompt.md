# Claude Prompt — README Improvement

## Purpose

Use this prompt to review and improve the README.md file for the NordHome project.
A strong README is often the first thing a recruiter reads — it needs to be clear, complete, and professional.

---

## Prompt

```
You are helping me improve the README.md file for my NordHome Retail Analytics portfolio project.

Please read the current README.md and then suggest improvements.

The README should achieve the following goals:
1. Explain what the project is and why it was built
2. Show the data pipeline clearly from raw CSV to Power BI dashboard
3. Tell another person exactly how to reproduce the project on their own machine
4. List what tools and technologies were used
5. Give a clear overview of the folder structure
6. Highlight what makes this project interesting from a data analytics perspective

Please check the README from these angles:

1. First impression
   - Is the title and opening paragraph clear and engaging?
   - Would a recruiter understand what this project is within the first 10 seconds?

2. Project overview
   - Is the business context explained briefly but clearly?
   - Is the dataset described (size, source, intentional issues)?
   - Is the pipeline explained at a high level?

3. Reproducibility
   - Are the setup steps complete and in the correct order?
   - Is the Python script path correct and does it match the actual file?
   - Are the PostgreSQL setup steps included (create database, schemas, load CSV)?
   - Is the execution order of SQL files clear?
   - Are Python dependencies listed or linked to a requirements.txt?

4. Folder structure
   - Is there a folder tree showing how the project is organized?
   - Does it match the actual current folder structure?

5. Technologies section
   - Are all tools used mentioned (PostgreSQL, Python, Power BI, Git)?
   - Are version numbers or notes included where helpful?

6. Portfolio presentation
   - Does the README show what skills were demonstrated?
   - Are any screenshots, diagrams, or images included or referenced?
   - Is the tone professional and clear?

Please return:
- A list of what is missing or incorrect
- Specific suggestions for each section
- A suggested README structure if the current one needs significant improvement
- Overall quality rating: Needs work / Good / Strong

Do not rewrite the entire README unless I ask — suggest improvements section by section.
```

---

## Known issues to fix in the current README

- Script path says `python generate_dataset.py` — actual path is `scripts/generate_retail_dataset.py`
- No PostgreSQL database setup instructions
- No execution order for SQL files
- No `requirements.txt` referenced
- Data folder is empty — this should be explained
- No folder structure overview

---

## When to use

- After making significant changes to the project structure
- Before sharing the project link with a recruiter
- When preparing the project for a portfolio submission
- After adding new features, analyses, or documentation

---

## Notes

- The README is the front page of the project on GitHub — it should always be up to date
- A recruiter may only read the README and look at the folder structure before deciding whether to dig deeper
- Keep instructions short but complete — use numbered steps and code blocks for commands
- Add a link to the Power BI dashboard if it is published online