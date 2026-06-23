# Color Usage — Practical Defaults & Self-Check

## Suggested palette roles

Keep these centralized in `base_style.py` (or equivalent shared style file) so every chart pulls from the same source rather than redefining color per-script.

- **Neutral / background:** a single grey, used for all non-highlighted data (e.g. `#B0B0B0` — confirm against the project's actual style file).
- **Accent / focus:** one consistent color reserved for the data point the chart's point is about.
- **Negative / warning:** red, used only when the meaning is genuinely negative.
- **Positive / good:** a green or blue, used only when the meaning is genuinely positive — confirm it doesn't clash with the accent color.

If a chart needs more than these four roles, that's usually a sign it's trying to say more than one thing — revisit the chart's core point before adding more colors.

## Where color should go

| Use color for | Don't use color for |
|---|---|
| The single data point or series the chart is about | Every category, by default, because the tool auto-assigns them |
| Highlighting a change, threshold, or outlier | Decoration, branding, or "making it pop" |
| A consistent meaning across the whole project (e.g. one accent = focus) | Different meanings in different charts (inconsistent signal) |
| Distinguishing 2–3 genuinely distinct groups when needed | Distinguishing many groups — use direct labeling instead |

## Pre-ship self-check

Run through these before considering a chart's color scheme final:

- If all color were removed from this chart, would information be lost, or just decoration?
- Is there exactly one thing the color is drawing the eye to?
- Does the accent color mean the same thing here as in every other chart in this project?
- If a colorblind reader saw this, would the point still come across?

If any answer is uncomfortable, the color usage needs another pass.
