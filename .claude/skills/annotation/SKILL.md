---
name: annotation
description: Guidance on annotating charts — titles, labels, callouts, and subtitles — based on Storytelling with Data principles. Use when the user is writing a chart title, adding labels or callouts to a chart, asking how to make a chart self-explanatory, or reviewing/improving any matplotlib/seaborn/plotly visualization that already has a chart type chosen. Trigger after chart-selection and before or alongside decluttering.
---

# Annotation

> A chart should not need a paragraph of surrounding text to be understood. Titles, labels, and callouts are what make a chart explain itself.

By the time you reach annotation, the Big Idea is written, the chart type is chosen, and color is directing attention to the right element. Annotation is the layer that tells the reader *why* that element matters — without them needing to ask.

---

## The core principle: words and visuals work together

A common mistake is treating text and chart as separate things — a generic axis-labelled chart, with all the explanation living in a paragraph above or below it. Knaflic's point is that this forces the reader to do the work of connecting the words to the visual themselves.

The fix is to bring the words *onto* the chart, next to the data they explain. A title that states the insight, a label on the one bar that matters, a short note next to the relevant point — these let the chart carry its own meaning.

---

## Titles: state the insight, not the axes

The most common annotation mistake is a title that describes what the chart shows rather than what it means.

| Weak title (describes the chart) | Strong title (states the insight) |
|---|---|
| "Sales by Region, 2025" | "The Northeast region drove 60% of 2025 growth" |
| "Customer Churn Rate Over Time" | "Churn has tripled since the pricing change in March" |
| "Defect Rate by Production Line" | "Line B's defect rate is 3x the plant average" |

A strong title is derived directly from the Big Idea — it should be the shortest version of that sentence that still carries the point of view. If you're struggling to write a strong title, that's often a sign the Big Idea itself isn't sharp enough yet (see `big_idea.md`).

**Practical rule:** if you covered the chart and only showed someone the title, they should be able to guess roughly what the data shows. If the title is interchangeable with a hundred other charts on the same topic, it's not doing its job.

---

## Labeling data directly

Direct labeling — putting the value or name right next to the data point — is usually better than forcing the reader to cross-reference a legend or axis.

**When to label directly:**
- The specific value of the one element the chart's point is about
- A threshold, target, or benchmark line
- An outlier or inflection point that needs explaining

**When not to label everything:**
- Labeling every single data point creates clutter and defeats the purpose of emphasis — see `color_usage.md`'s grey-first principle. The same logic applies to labels: label the one or two things that matter, not all of them.

**Removing the legend.** If there are only one or two highlighted series, a direct label next to the line or bar usually replaces the legend entirely. This removes the back-and-forth eye movement between chart and key, which is friction the reader doesn't need.

---

## Callouts and annotations on the chart itself

A callout is a short note placed directly next to a specific point — explaining a spike, a dip, an anomaly, or a turning point the reader would otherwise have to ask about.

**Good callouts are:**
- Short — a phrase or single sentence, not a paragraph
- Placed close to what they explain — proximity reduces the work of connecting text to visual
- Answering the question the reader will actually ask when they see that point (e.g. "What happened here?" → "Server outage, March 14")

**Callouts are not:**
- A running commentary on every data point
- A substitute for fixing a confusing chart — if the chart needs five callouts to make sense, the chart itself may be too complex (revisit chart type or consider splitting into two charts)

---

## Subtitles and context lines

A subtitle (a line beneath the title) is useful for adding necessary context that doesn't fit in the title itself — units, date ranges, or a caveat.

Keep it short and factual. The subtitle's job is to remove ambiguity, not to add a second insight. If the subtitle is making its own point, that point probably belongs in its own chart or its own title.

---

## What to remove

Annotation is as much about subtraction as addition. Common clutter to cut:

- **Redundant axis titles** when the chart title or labels already make the units obvious
- **Gridlines as the only way to read a value** — if a value matters, label it directly instead of asking the reader to trace a line to the axis
- **A legend, when direct labels would work instead**
- **Decorative text** that doesn't help the reader get to the insight faster

The test for any piece of text on a chart: does removing it lose information, or does the chart become *clearer*? If clearer, cut it.

---

## A quick self-check before shipping a chart

- Does the title state the insight, or just describe the axes?
- If someone covered everything except the title, could they guess the point?
- Are the right one or two things labeled directly, with everything else left unlabeled?
- Could I remove the legend by labeling the data directly instead?
- Does every word on the chart earn its place?

---

## After this

Once annotation is in place, do a final declutter pass — see `dashboard_design.md` if this chart is part of a multi-chart layout, since layout-level decisions (sizing, arrangement, repetition) come after individual charts are finalized.

---

## Source

The "words and visuals work together" framing, direct labeling guidance, and the title-as-insight principle are drawn from Chapter 6 of *Storytelling with Data* (Knaflic, 2015). The comparison tables and self-check are toolkit-specific and original to this repo.