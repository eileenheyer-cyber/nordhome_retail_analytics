---
name: nordhome_chart_style
description: NordHome chart style reference — design values, color tokens, layout constants, and chart conventions for all NordHome EDA charts. Use this skill whenever building or reviewing a chart for the NordHome EDA notebook or any NordHome deliverable. Trigger when the user writes matplotlib/seaborn code in this project, asks how to format a title/axis/layout, wants to apply the NordHome style, or references base_style.py.
---

# NordHome EDA Chart Style Guide

Use this style for all NordHome Retail EDA charts.  
Charts should be clean, business-oriented, readable, and focused on one clear insight.

---

## General chart principles

- Use the chart title to communicate the main finding, not only the metric name.
- Use the subtitle to explain the business interpretation.
- Avoid decorative colors.
- Use blue for the main business metric.
- Use grey for supporting or comparison metrics.
- Remove borders (spines).
- Use light horizontal grid lines only — no vertical grid lines.
- Use data labels when the exact value matters.
- Avoid cluttered legends and unnecessary annotations.

---

## Reusable design values

```python
# Figure
FIGSIZE = (14, 6)

# Layout
LAYOUT_LEFT   = 0.08
LAYOUT_RIGHT  = 0.98
LAYOUT_TOP    = 0.76
LAYOUT_BOTTOM = 0.18
LAYOUT_WSPACE = 0.22

# Title block positions (figure-fraction coordinates)
TITLE_X    = 0.08
TITLE_Y    = 0.94
SUBTITLE_X = 0.08
SUBTITLE_Y = 0.875

# Font sizes
MAIN_TITLE_SIZE  = 20
SUBTITLE_SIZE    = 11.5
CHART_TITLE_SIZE = 13
AXIS_LABEL_SIZE  = 11
TICK_LABEL_SIZE  = 10.5
DATA_LABEL_SIZE  = 10.5
FOOTNOTE_SIZE    = 9.5
LEGEND_SIZE      = 10.5

# Font weight
MAIN_TITLE_WEIGHT = 'bold'

# Colors
BLUE      = '#4C78A8'   # main business metric
GREY      = '#B0B7C3'   # supporting / comparison metric
ORANGE    = '#F2632D'    # highlight / accent metric
TEXT_GREY = '#5A5A5A'   # subtitle and secondary text
DARK_TEXT = '#333333'   # primary text
AXIS_TEXT = '#444444'   # axis tick labels
GRID_GREY = '#E6E6E6'   # horizontal grid lines

# Grid
GRID_LINEWIDTH = 0.8
GRID_ALPHA     = 0.6

# Bars
SINGLE_BAR_WIDTH  = 0.40
GROUPED_BAR_WIDTH = 0.34

# Left chart manual spacing (for side-by-side layouts)
X_LEFT    = [0, 0.75]
LEFT_XLIM = (-0.25, 1.00)

# Title padding inside subplots
CHART_TITLE_PAD = 8

# Legend
LEGEND_BBOX = (0.5, -0.08)

# Footnote
FOOTNOTE_X = 0.08
FOOTNOTE_Y = 0.045
```

---

## Title block pattern

Place the main title and subtitle using `fig.text` at figure-fraction coordinates, above the subplots:

```python
fig.text(TITLE_X, TITLE_Y, "Main finding in plain language",
         fontsize=MAIN_TITLE_SIZE, fontweight=MAIN_TITLE_WEIGHT,
         color=DARK_TEXT, va='top')

fig.text(SUBTITLE_X, SUBTITLE_Y,
         "One sentence explaining the business interpretation.",
         fontsize=SUBTITLE_SIZE, color=TEXT_GREY, va='top')
```

---

## Layout pattern

Always call `fig.subplots_adjust` after all chart elements are drawn:

```python
fig.subplots_adjust(
    left=LAYOUT_LEFT,
    right=LAYOUT_RIGHT,
    top=LAYOUT_TOP,
    bottom=LAYOUT_BOTTOM,
    wspace=LAYOUT_WSPACE
)
```

---

## Axis style rules

```python
# Horizontal grid lines only
ax.yaxis.grid(True, color=GRID_GREY, linewidth=GRID_LINEWIDTH, alpha=GRID_ALPHA)
ax.xaxis.grid(False)
ax.set_axisbelow(True)

# Remove all spines
for spine in ax.spines.values():
    spine.set_visible(False)

# Tick label style
ax.tick_params(axis='both', labelsize=TICK_LABEL_SIZE, colors=AXIS_TEXT)
```

---

## Subplot chart title

Each individual subplot gets its own title with `ax.set_title`:

```python
ax.set_title("Metric Name", fontsize=CHART_TITLE_SIZE,
             fontweight='bold', pad=CHART_TITLE_PAD, loc='left')
```

---

## Footnote

Add a footnote at the bottom of the figure for data sources or caveats:

```python
fig.text(FOOTNOTE_X, FOOTNOTE_Y,
         "Source: NordHome mart schema · Excludes unknown customers",
         fontsize=FOOTNOTE_SIZE, color=TEXT_GREY)
```

---

## savefig convention

```python
plt.savefig("figures/my_chart.png", dpi=150, bbox_inches="tight")
plt.show()
```

- Save to `04_EDA/figures/<descriptive_name>.png`
- Always `dpi=150, bbox_inches="tight"`
- Reference in `insights.md` as: `**Chart:** [Description](figures/my_chart.png)`

---

## Code generation preference

These rules apply when generating or editing chart code for this project.

- When the user is still adjusting a chart, use simple and explicit Matplotlib code.
- Do not over-engineer chart code.
- Avoid unnecessary helper functions.
- Avoid defining many constants unless a reusable template is explicitly requested.
- Use actual values directly when adjusting spacing, font size, colors, bar width, or layout — e.g. `fontsize=13`, not `fontsize=CHART_TITLE_SIZE`.
- Only use constants and helper functions for finalized reusable chart templates.
- Prioritize readability and learning value over compact code.


## Common chart types

### 1. Simple bar chart

Use for comparing categories such as customer groups, product categories, countries, or return reasons.

Rules:
- Use blue for the main metric.
- Use grey only for secondary/supporting groups.
- Use `width=0.40–0.45` for two-category bar charts.
- Use horizontal grid lines only.
- Remove borders.
- Add data labels when exact values matter.
- Title should state the insight, not only the metric.

### 2. Grouped bar chart

Use when comparing two related metrics across the same groups, for example average vs median order value.

Rules:
- Blue = main metric.
- Grey = supporting metric.
- Keep legend below the chart.
- Avoid more than two bars per group unless necessary.
- Use rounded labels for readability.

### 3. Ranked bar chart

Use for top-N comparisons.

Rules:
- Sort values descending.
- Use horizontal bars when category names are long.
- Use darker color for the highest value if using a gradient.
- Avoid too many categories; prefer top 10 or top 15.
- Add value labels at the end of bars.

### 4. Line chart

Use for time trends, such as monthly revenue or order volume.

Rules:
- Use line charts only when the x-axis has natural order.
- Keep markers small or remove them if the line is crowded.
- Use blue for the main trend.
- Use grey for comparison lines.
- Subtitle should explain the trend pattern.
