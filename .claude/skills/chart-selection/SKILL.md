---
name: chart-selection
description: Decision framework for choosing the right chart type based on Storytelling with Data principles. Use this skill whenever the user is building, reviewing, or discussing a data visualization, chart, plot, or graph — including matplotlib/seaborn/plotly code, dashboard design, or any task that involves picking between bar/line/pie/scatter/histogram chart types. Also use when the user asks "what chart should I use", mentions chart selection, or is working on the NordHome Retail EDA/dashboard deliverables. Make sure to trigger on any visualization or charting task even if the user doesn't explicitly mention "chart selection" by name.
---

# Chart Selection

Decision framework for matching a chart type to the relationship in the data, based on *Storytelling with Data* (Knaflic, 2015).

## When to apply this

Before writing any plotting code, identify which relationship the data shows. The chart type follows from the relationship — not from habit, not from what's easiest to call in matplotlib/seaborn/plotly.

If the user has not stated a Big Idea (a one-sentence point of view for the chart), ask for it first, or infer the likely one from context and state the assumption before proceeding.

## The five relationships

| Relationship | Question | Chart | Avoid |
|---|---|---|---|
| **Comparison** | How do these differ? | Horizontal bar | Pie, radar |
| **Trend** | How does this change over time? | Line (continuous) / bar (discrete points) | Bar for long series |
| **Distribution** | How is this spread out? | Histogram, box plot | Bar chart of averages only |
| **Composition** | How do parts make a whole? | Stacked bar (pie only if 2–3 categories) | Exploded pie, 3D |
| **Correlation** | Do two variables move together? | Scatter + trend line | Line chart, bubble (unless size is meaningful) |

## Hard rules

- **Pie charts are almost always wrong.** Humans judge length accurately and angle/area poorly. Default to a bar chart unless there are 2–3 categories and the point is one dominant share.
- **No 3D charts, ever.** The third dimension adds no information and distorts area comparisons.
- **No dual-axis charts.** Rescaling either axis can manufacture a false visual relationship. If two measures both matter, build two charts.
- **Simplicity beats novelty.** If two chart types both work, pick the one the audience has already seen. An unfamiliar chart type makes the reader learn how to decode it before they can understand what it says.

## Horizontal ranking bar — implementation rules

When the chosen type is **horizontal bar for ranking** (comparison sorted by value, e.g. revenue by country, units by category), always apply all four of these rules:

### 1. Sort ascending in SQL
Smallest value at index 0 → bottom of chart. Largest at the last index → top of chart.
```sql
ORDER BY revenue ASC
```

### 2. Color gradient — same hue, light → dark, bottom → top
Use `BLUES` from `base_style.py`. Light at the bottom (lowest rank), dark at the top (highest rank).
```python
n = len(df)
colors = [BLUES(0.25 + 0.55 * i / max(n - 1, 1)) for i in range(n)]
ax.barh(df["label"], df["value"], color=colors)
```
Never use a flat single color for ranking charts — the gradient reinforces the rank visually.

### 3. K notation on the x-axis — always
Always use `eur_k` from `base_style.py` for the x-axis formatter:
```python
ax.xaxis.set_major_formatter(eur_k)   # shows €500K, €3,000K
```
Switch to `eur_m` only if all values exceed €1 M **and** the K numbers would be 5+ digits (e.g. €10,000K → prefer €10M). Otherwise default to K.

### 4. Label only the top bar
Direct value label on the #1 bar (last row after ascending sort) in the accent color only:
```python
top = df["value"].iloc[-1]
ax.text(top * 1.01, len(df) - 1, f"€{top/1_000:,.0f}K",
        va="center", fontsize=9, color=ACCENT, fontweight="bold")
```

---

## Workflow when this skill triggers

1. Identify the relationship (comparison / trend / distribution / composition / correlation) from what the user is trying to show.
2. Pick the chart type from the table above.
3. If the user's existing code or request uses a chart type that conflicts with this table (e.g. a pie chart with 6 categories, a dual-axis line chart), flag it and suggest the better alternative — don't silently go along with a suboptimal choice.
4. State which relationship you identified and why, so the user can correct it if you inferred wrong.

## Reference

See `references/decision_trees.md` for the full per-relationship decision trees with sample-size and category-count thresholds.

## Source

Chapters 2–3 of *Storytelling with Data* (Knaflic, 2015).
