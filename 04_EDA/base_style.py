"""Shared visual style tokens and helpers for NordHome EDA charts."""

import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

# ── Color tokens ──────────────────────────────────────────────────────────────
ACCENT     = "steelblue" # highlight — key finding / top-ranked bar
GREY_LABEL = "#aaaaaa"   # overline subject line
GREY_TEXT  = "#888888"   # headline non-highlighted words
BLUES      = plt.cm.Blues  # ranking-bar gradient (light→dark, bottom→top)

# ── Number formatters ─────────────────────────────────────────────────────────
eur   = mticker.FuncFormatter(lambda x, _: f"€{x:,.0f}")
eur_k = mticker.FuncFormatter(lambda x, _: f"€{x/1_000:,.0f}K")
eur_m = mticker.FuncFormatter(lambda x, _: f"€{x/1_000_000:.1f}M")
pct   = mticker.FuncFormatter(lambda x, _: f"{x:.1f}%")

# ── Title sizes ───────────────────────────────────────────────────────────────
_LABEL_SIZE = 9    # overline subject
_TEXT_SIZE  = 16   # headline grey context words
_KEY_SIZE   = 18   # headline orange key phrase (≤3 words)


def add_chart_title(ax, subject, grey_text, key_phrase):
    """
    Two-level chart title above an axes:
      subject    – small grey overline, names the chart dimension
      grey_text  – headline context in grey (font-size 16)
      key_phrase – ≤3-word key finding in orange (font-size 18, medium weight)

    Grey prefix and orange key phrase are rendered inline on the same baseline.
    Call this function after all chart elements are set; call plt.show() after.
    """
    # Overline
    ax.text(0, 1.14, subject, transform=ax.transAxes,
            fontsize=_LABEL_SIZE, color=GREY_LABEL, va="baseline")

    # Grey part of headline — rendered first so we can measure its display width
    t_grey = ax.text(0, 1.03, grey_text + " ", transform=ax.transAxes,
                     fontsize=_TEXT_SIZE, color=GREY_TEXT, fontweight="normal",
                     va="baseline")

    # Draw to get accurate bounding boxes
    ax.figure.canvas.draw()
    renderer = ax.figure.canvas.get_renderer()

    bb_txt = t_grey.get_window_extent(renderer=renderer)
    bb_ax  = ax.get_window_extent(renderer=renderer)
    x_key  = (bb_txt.x1 - bb_ax.x0) / bb_ax.width   # axes-fraction x after grey text

    # Orange key phrase immediately after grey text, same baseline
    ax.text(x_key, 1.03, key_phrase, transform=ax.transAxes,
            fontsize=_KEY_SIZE, color=ACCENT, fontweight="medium", va="baseline")
