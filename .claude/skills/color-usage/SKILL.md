---
name: color-usage
description: Rules for using color deliberately in data visualizations, based on Storytelling with Data principles. Use this skill whenever the user is choosing colors, palettes, or highlighting for a chart, plot, or graph — including matplotlib/seaborn/plotly color arguments, choosing accent colors, deciding which bars/lines/points to highlight, or reviewing a chart's color scheme. Also trigger when the user's code auto-assigns a different color per category, uses more than 2-3 colors on one chart, or is working on the NordHome Retail base_style.py / chart styling. Make sure to trigger even if the user doesn't say "color" explicitly — e.g. "make this bar stand out", "highlight the important one", "this chart looks too busy/colorful".
---

# Color Usage

Rules for deliberate, attention-directing color choices in charts, based on *Storytelling with Data* (Knaflic, 2015), Chapter 5.

## When to apply this

Apply after the chart type is already chosen (see `chart-selection` skill). Color's job is narrow: make the one thing that matters impossible to miss, and make everything else recede.

## The grey-first rule (the single most important rule here)

Default every element in a chart to grey. Add color only to the data point(s) or category that the chart's point is actually about.

```
Default state:  Every element is grey.
Add color:      Only to what the point is about.
Result:         One or two colored elements against a grey field.
```

If the user's existing code uses a different color per category by default (common with seaborn/plotly defaults), flag this — it's the most frequent violation of this rule, and it usually means the charting library's default palette was never overridden.

## NordHome project accent color

`ACCENT = "steelblue"` — defined once in `04_EDA/base_style.py`. Import it from there; never hardcode the color separately in individual chart cells.

**Semantic meaning:** `ACCENT` marks the key finding — the top-ranked bar in a ranking chart, the highlighted data point in a callout, or the orange key phrase in a chart title. It should mean the same thing on every chart in the dashboard.

**Where it's used:**
- Top bar label in horizontal ranking charts (via `color=ACCENT`)
- The `BLUES` gradient (same color family as steelblue) for ranking bar fills
- Any single data point that is the point of the chart

---

## Hard rules

- **One consistent accent color** across the whole project, always meaning "this is the important thing." Don't let it mean different things in different charts.
- **Red = negative/warning, green = positive/good** — don't repurpose these for arbitrary categorical distinctions. A red bar that doesn't mean "bad" fights the reader's instinct.
- **Max 2–3 colors per chart.** More than that is usually a sign color is being used to separate categories that should be separated by direct labeling, sorting, or faceting instead.
- **Check colorblind accessibility** whenever red and green are both present and meaningful — add a secondary cue (position, label, pattern) so the distinction doesn't rely on color alone.

## Before reaching for color, consider these alternatives

Color is one of several "preattentive attributes" the brain processes before conscious attention — but it's not the only one, and it's overused because it's the easiest to apply:

- **Position** — sorting a bar chart by value often draws the eye to the extremes with zero color needed.
- **Size/weight** — a bolder or larger label can highlight a number without touching the palette.
- **Proximity** — placing a callout physically next to the relevant data point can remove the need for a legend (and a color-coded key) entirely.

If the user asks "how do I make this stand out" and color isn't the only lever available, mention position or size as alternatives, not just a color answer.

## Workflow when this skill triggers

1. Check whether color is currently being used as a spotlight (1-2 highlighted elements) or a paint bucket (every category a different color). Flag the latter.
2. Confirm there's a single point the color should be directing attention to — if there isn't one, that's a sign the chart itself may be trying to say more than one thing (point back to the Big Idea).
3. Recommend grey as the default, with one accent color reserved for the point.
4. If red/green are both present, check whether the meaning matches the cultural convention (red=bad, green=good) and whether a colorblind-safe secondary cue exists.

## Reference

See `references/practical_defaults.md` for suggested palette roles and the pre-ship self-check checklist.

## Source

Chapter 5 of *Storytelling with Data* (Knaflic, 2015) — the grey-first principle, the spotlight framing, and the preattentive attributes concept are Knaflic's own framing.
