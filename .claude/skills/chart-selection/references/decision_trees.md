# Chart Selection — Decision Trees

Detailed thresholds and reasoning for each relationship type. Read this when the SKILL.md table isn't specific enough for the case at hand.

## Comparison

```
How many categories?
├── Few (2–7)  →  Horizontal bar chart
│                 (easier to read labels, natural ranking order)
└── Many (8+)  →  Still a bar chart, but reconsider:
                  can the point survive this many categories?
                  If not, group or filter before building.
```

Avoid radar/spider charts — they distort comparison by encoding values as distance from a centre point across arbitrary axes.

## Trend

```
Is the change continuous or discrete?
├── Continuous (daily, monthly, quarterly)   →  Line chart
└── Discrete (e.g. annual survey snapshots)  →  Bar chart or connected dot plot
```

Use a line chart only when the connection between points is meaningful — i.e. the thing being measured existed continuously between the data points. Avoid bar charts for long continuous series; they become unreadable beyond ~12 bars.

## Distribution

```
How many data points?
├── Few (< ~30)         →  Strip plot or dot plot
├── Moderate (~30–200)  →  Box plot (if audience knows how to read one)
│                          or violin plot
└── Many (200+)         →  Histogram
```

Use a box plot when comparing distributions across multiple groups side by side. Avoid summarising a distribution as a single average in a bar chart unless the spread genuinely doesn't matter — an average hides the shape.

## Composition

```
Is the composition changing over time?
├── No (static snapshot)  →  Single stacked bar or waffle chart
│                            (pie chart only if 2–3 categories max)
└── Yes (over time)       →  Stacked bar chart (not stacked area —
                             harder to read individual segment changes)
```

## Correlation

```
Are you showing the relationship itself, or individual data points?
├── The relationship (pattern, trend)  →  Scatter plot with a trend line
└── Individual points matter            →  Scatter plot, labelled selectively
```

Avoid bubble charts unless the third variable (bubble size) is central to the point — bubble size is hard to read accurately and adds cognitive load.

## Quick reference table

| You want to show | Reach for | Avoid |
|---|---|---|
| How categories compare | Horizontal bar chart | Pie chart, radar chart |
| Change over continuous time | Line chart | Bar chart (long series) |
| Change at discrete time points | Bar chart | Line chart |
| How values are distributed | Histogram, box plot | Bar chart of averages |
| How parts make a whole | Stacked bar, pie (2–3 cats only) | 3D charts, exploded pie |
| Whether two variables correlate | Scatter plot | Line chart, bubble chart |
