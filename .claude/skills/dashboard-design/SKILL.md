---
name: dashboard-design
description: Guidance on dashboard layout, visual hierarchy, and multi-chart consistency based on Storytelling with Data principles. Use when the user is designing or reviewing a dashboard, arranging multiple charts on a single canvas, working on Power BI/Tableau layout, asking how charts should be sized or ordered, or discussing the NordHome Retail dashboard deliverable. Trigger after chart-selection and annotation are applied to individual charts.
---

# Dashboard Design

> A dashboard is not a collection of charts — it is a single visual argument made of several parts. Layout, hierarchy, and flow matter as much as any individual chart's correctness.

Everything in `chart_selection.md`, `color_usage.md`, and `annotation.md` applies to each chart on a dashboard individually. This file covers what changes when multiple charts share a canvas: how they're arranged, how the eye moves between them, and how much each one is allowed to say.

---

## Start with one Big Idea for the whole dashboard, not just each chart

A dashboard built from charts that each have their own unrelated Big Idea will feel scattered, even if every individual chart is well made. Before laying anything out, write a single Big Idea for the dashboard as a whole — the same one-sentence test from `big_idea.md` applies at this level too.

Once the dashboard's Big Idea is clear, each chart's role becomes one of:
- **Carrying the main point** — usually one chart, given the most visual weight
- **Supporting the main point** — providing context, breakdown, or detail
- **Providing drill-down** — answering "why" or "what specifically" for someone who wants more

Not every chart needs to carry equal weight. A dashboard where every chart is the same size and shouts the same loudness has no hierarchy, and the reader doesn't know where to look first.

---

## Visual hierarchy: guide the eye in order

Readers don't scan a dashboard randomly — they tend to look top-left first, then move in a Z or F pattern. Use this:

- **Put the most important chart top-left**, or wherever the reader's eye naturally lands first.
- **Size reflects importance.** The chart carrying the main point should be visually larger or more prominent than supporting charts, not just first in reading order.
- **Group related charts together.** If three charts all support one sub-point, place them near each other so the relationship is visually obvious, not something the reader has to infer from labels alone.

```
Typical hierarchy layout:
┌─────────────────────────┬──────────┐
│                         │ Support  │
│   Main chart            │ chart A  │
│   (carries Big Idea)    ├──────────┤
│                         │ Support  │
│                         │ chart B  │
├─────────────┬───────────┴──────────┤
│ Drill-down  │ Drill-down           │
│ detail 1    │ detail 2             │
└─────────────┴──────────────────────┘
```

---

## Consistency across charts on the same dashboard

This is where dashboards fail most often: each chart is individually fine, but they don't feel like they belong together.

- **One accent color, used the same way, across every chart on the dashboard.** If orange means "the metric we're highlighting" on chart 1, it must mean the same thing on chart 4 — not a different category by coincidence of palette order.
- **Same font, same title style, same label conventions** throughout. Switching chart libraries or styles mid-dashboard is usually visible immediately, even to a non-technical viewer.
- **Same level of decimal precision and units** across charts showing comparable numbers — inconsistency here reads as sloppiness even when the underlying data is correct.
- **Aligned gridlines and consistent spacing**, where charts share an edge — small misalignments are subtle but cumulatively make a dashboard feel unpolished.

If you've built a shared style file (e.g. `base_style.py`), a dashboard is the place where reusing it matters most — manually tweaking one chart's colors breaks the whole dashboard's consistency.

---

## Reduce, don't just arrange

Before finalizing layout, ask whether every chart on the dashboard needs to exist at all. A common failure mode is including a chart because the data was available, not because it serves the dashboard's Big Idea.

- **Cut charts that repeat information** another chart already shows from a different angle, unless the second angle genuinely adds something the first didn't.
- **Cut charts that don't connect to the Big Idea.** If a chart can be removed without changing what the dashboard communicates, it's clutter at the dashboard level, the same way an unnecessary gridline is clutter at the chart level.
- **Fewer, well-chosen charts beat many mediocre ones.** A dashboard with 4 sharp, hierarchy-respecting charts communicates more reliably than one with 10 evenly-weighted ones.

---

## White space is part of the design

Cramming charts edge-to-edge to fit more on screen usually backfires — it removes the visual breathing room that helps the reader separate one idea from the next.

- Leave consistent margins between charts.
- Don't shrink a chart so much that its labels become unreadable just to fit another chart in the same row.
- If the dashboard feels crowded, the fix is usually to cut a chart, not to shrink all of them further.

---

## A quick self-check before shipping a dashboard

- Could I state this dashboard's Big Idea in one sentence, the same way I would for a single chart?
- Does the most important chart get the most visual weight, or is everything sized the same?
- Is the accent color used consistently for the same meaning across every chart?
- If I removed any one chart, would the dashboard's message change? If not, consider cutting it.
- Does the eye know where to look first, or does the layout leave that to chance?

---

## Source

The visual hierarchy and consistency principles are drawn from Chapter 7 of *Storytelling with Data* (Knaflic, 2015), which focuses on pulling individual elements together into a cohesive whole. The layout diagram, reduction guidance, and self-check are toolkit-specific and original to this repo.