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

## Emphasizing what matters in the subtitle

**Don't emphasize inside the title.** The title is already the largest, boldest,
darkest element on the chart — there's no neutral field for a highlighted word to
contrast against. The title as a whole is the highlight. Hard rule, not a suggestion.

**Emphasize in the subtitle instead.** The subtitle is `TEXT_GREY` (`#5A5A5A`) —
a neutral field — so bolding a word, phrase, or figure makes it stand out. Limit
bold to the one or two things that carry the Big Idea. If half the subtitle is bold,
nothing is emphasized. Same grey-first logic as `color-usage`, applied to text.

**Use weight, never the accent color.** The accent color marks data elements;
applying it to subtitle text gives one color two meanings. Emphasize with
bold/weight only. See `color-usage` → "Don't reuse the accent color to emphasize text."

**If the emphasis is a figure, verify it first.** A highlighted number invites
scrutiny. Recompute it from the source values and confirm the title, subtitle,
and chart data all state the same value at the same rounding before emphasizing.

> `fig.text` does not support inline bold in a single string. To bold one segment,
> split the subtitle into two `fig.text` calls placed at the correct x-offset, or
> use `ax.annotate` with `fontweight='bold'` for the emphasized part.

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
- If values sit close together (no clear rank story) or you're building
  multi-panel comparisons across metrics with different scales, use the
  spotlight pattern (#4) instead of a gradient.

### 4. Spotlight bar chart — no axis, every bar labeled

Use when every bar's exact value matters and the values are close together
(e.g. category revenue within a ~10% band), so a numeric axis would just repeat
what the labels already say. Also the default choice for side-by-side panels
comparing two metrics with different units/scales (e.g. revenue vs. units sold)
— each panel keeps its own bars-only look instead of forcing a shared axis.

Rules:
- **Never rely on matplotlib's default bar thickness.** Always pass an explicit
  `height=` (horizontal `barh`) or `width=` (vertical `bar`) — default is `0.8`,
  which reads as bulky next to direct end-labels. Use `0.5` as the default for
  ranked/spotlight horizontal bars unless the user asks for something else.
- **Bars: grey-first, one spotlight.** All bars `GREY` (`#B0B7C3`) except the
  single bar the chart's point is about (usually the top-ranked one), which
  gets `ACCENT`/`BLUE`. Do **not** use a light→dark gradient here — a gradient
  implies a fixed rank order, which is misleading if the two panels don't agree
  on rank (e.g. one category leads revenue, another leads units sold).
- **Remove the axis entirely**: `ax.set_xticks([])` (or `set_yticks([])` for
  vertical bars), no gridlines (`ax.xaxis.grid(False)` / `ax.yaxis.grid(False)`),
  no spines. The direct labels are the only source of numbers.
- **Label every bar**, positioned just past the bar end
  (`bar_value * 1.02`), not only the top one.
  - Top/spotlighted bar: `color=ACCENT`, `fontweight='bold'`.
  - All other bars: `color=DARK_TEXT` (`#333333`), `fontweight='normal'`.
- Add `ax.margins(x=0.15)` (or `y=` for vertical) so the longest label isn't
  clipped at the figure edge now that there's no axis defining the boundary.
- For multi-panel comparisons, reuse the same category order and the same
  per-category color assignment across panels so a given category stays the
  same color in every panel — the eye should not have to re-map colors per
  panel.
- Category tick labels: keep on the leftmost panel only; drop
  (`set_yticklabels([])`) on subsequent panels to avoid repeating them.

### 5. Line chart

Use for time trends, such as monthly revenue or order volume.

Rules:
- Use line charts only when the x-axis has natural order.
- Keep markers small or remove them if the line is crowded.
- Use blue for the main trend.
- Use grey for comparison lines.
- Subtitle should explain the trend pattern.

### 6. Distribution + threshold chart

Use for "how is X distributed, and which records fall outside the typical
range" questions (e.g. revenue per customer with IQR outliers). Prefer this
over a box plot when the outlier count is large enough that jittered points
would be hard to read individually.

Rules:
- **Histogram, not box plot**, as the default for this question shape — a box
  plot with many jittered outlier points is harder to read than a colored
  histogram tail.
- **Bars: grey/blue-first, one spotlight.** Bars below the threshold in
  `BLUE`/`ACCENT` (the typical range), bars past the threshold in `ORANGE`
  (the flagged group) — same grey/accent-first logic as every other chart,
  applied per-bar via bin edge instead of per-category.
- **Threshold line, labeled directly**: `ax.axvline(threshold, linestyle='--')`
  with the threshold value as a direct label next to the line — not just a
  legend entry.
- **Check tail legibility before deciding whether to cap the axis** — this is
  a diagnostic, not a default. After plotting, look at the flagged region: are
  the bars actually visible, or have they shrunk to sub-pixel slivers with a
  long dead gap before the data max? Only if that symptom shows up, cap the
  axis (`ax.set_xlim(0, x_cap)`) to give the legible part of the tail more
  visual weight. A tail that's already legible at full scale should be left
  alone — don't cap pre-emptively, and don't reuse a cap value from a
  previous chart on a differently-shaped distribution.
- **If you cap the axis, disclose what's cut — this part is not optional.**
  Add a small note stating how many records fall outside the visible range
  and what the true max is (e.g. "118 customers extend further, up to
  €30,568"). Never truncate an axis silently — same "don't hide data quality
  issues" principle as everywhere else in this project, applied to axis range
  instead of dirty rows.
- **Connect callouts to the data they describe.** A count/share label (e.g.
  "267 customers (3.4%) beyond this line") should sit near the bars it refers
  to, with a leader line/arrow if it can't sit directly adjacent — see the
  `annotation` skill's callout-placement rule. Floating text far from the
  flagged bars forces the reader to guess what it's pointing at.


## Mandatory post-build review (do not skip)

After creating any chart with this skill, you are NOT done. Before presenting
the chart to the user, you MUST read and validate it against these four skills,
in this order. Read each `SKILL.md` fresh — do not rely on memory of them.

1. **chart-selection** (`skills/chart-selection/SKILL.md`)
   - Name the relationship (comparison / trend / distribution / composition /
     correlation). Confirm the chart type matches it.
   - Confirm no pie/radar/3D/dual-axis chart snuck in where a simpler type wins.

2. **color-usage** (`skills/color-usage/SKILL.md`)
   - Grey-first: is everything grey except the 1–2 elements the Big Idea is about?
   - Is the accent color used for the same meaning as elsewhere?
   - Would the point survive for a colorblind reader?

3. **annotation** (`skills/annotation/SKILL.md`)
   - Does the title state the insight, not just describe the axes?
   - Are only the 1–2 things that matter labeled directly?
   - Can the legend be replaced by direct labels?
   - Do the title and subtitle agree with each other and with the data
     (same ratio, same rounding, same units)?

4. **decluttering** (`skills/decluttering/SKILL.md`)
   - Run the "would I miss it?" test on gridlines, borders, tick marks, and axes.
   - If values are labeled directly, are redundant axes/gridlines removed?

### Output of this review
- If the chart passes all four, state briefly that it was checked and passed.
- If any check fails, FIX the chart, then re-run the failing check.
- Report each fix in one line (e.g. "color-usage: made non-highlighted bars grey").
