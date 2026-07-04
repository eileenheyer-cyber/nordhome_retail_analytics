"""Shared visual style tokens and helpers for NordHome EDA charts."""

import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

# ── Color tokens ──────────────────────────────────────────────────────────────
ACCENT     = "steelblue" # highlight — key finding / top-ranked bar
ORANGE     = "#F2632D"   # project standard highlight orange (CLAUDE.md chart style guide)
GREY_LABEL = "#aaaaaa"   # overline subject line
GREY_TEXT  = "#888888"   # headline non-highlighted words
BLUES      = plt.cm.Blues  # ranking-bar gradient (light→dark, bottom→top)

# ── Number formatters ─────────────────────────────────────────────────────────
eur   = mticker.FuncFormatter(lambda x, _: f"€{x:,.0f}")
eur_k = mticker.FuncFormatter(lambda x, _: f"€{x/1_000:,.0f}K")
eur_m = mticker.FuncFormatter(lambda x, _: f"€{x/1_000_000:.1f}M")
pct   = mticker.FuncFormatter(lambda x, _: f"{x:.1f}%")

# ── Title sizes ───────────────────────────────────────────────────────────────
_LABEL_SIZE = 9    # overline subject (add_chart_title, legacy — new charts use add_title_subtitle)
_TEXT_SIZE  = 16   # headline grey context words
_KEY_SIZE   = 18   # headline orange key phrase (≤3 words)

TITLE_SIZE    = 24   # main chart title (add_title_subtitle)
SUBTITLE_SIZE = 18   # supporting subtitle line (add_title_subtitle)
TITLE_COLOR    = "#333333"
SUBTITLE_COLOR = "#5A5A5A"

# ── Default figure layout ─────────────────────────────────────────────────────
# Project-standard margins — edit here to change every chart that calls apply_layout().
LAYOUT_LEFT   = 0.05
LAYOUT_RIGHT  = 0.98
LAYOUT_TOP    = 0.58
LAYOUT_BOTTOM = 0.1
LAYOUT_WSPACE = 0.3


def apply_layout(fig, **overrides):
    """
    Apply the project's standard figure margins (left/right/top/bottom/wspace).
    Pass overrides (e.g. wspace=0.2) to adjust one chart without touching the
    shared defaults above.
    """
    params = dict(left=LAYOUT_LEFT, right=LAYOUT_RIGHT, top=LAYOUT_TOP,
                  bottom=LAYOUT_BOTTOM, wspace=LAYOUT_WSPACE)
    params.update(overrides)
    fig.subplots_adjust(**params)


def add_title_subtitle(ax, title, subtitle, title_y=1.28, subtitle_y=1.10,
                        title_size=TITLE_SIZE, subtitle_size=SUBTITLE_SIZE,
                        title_color=TITLE_COLOR, subtitle_color=SUBTITLE_COLOR):
    """
    Plain two-line chart title, no overline: bold main title + grey subtitle.
    Per the annotation skill's rule, emphasis belongs in the subtitle via bold
    weight, not accent color — don't color part of the title or subtitle orange.
    title_y/subtitle_y are axes-fraction (>1 = above the axes); for a dedicated
    title-only axes (e.g. a multi-panel figure), pass values within 0-1 instead.
    Call this after fig.subplots_adjust/apply_layout; call plt.show() after.
    """
    ax.text(0, title_y, title, transform=ax.transAxes,
            fontsize=title_size, fontweight="bold", color=title_color, va="baseline")
    ax.text(0, subtitle_y, subtitle, transform=ax.transAxes,
            fontsize=subtitle_size, color=subtitle_color, va="baseline")


def add_chart_title(ax, subject, grey_text, key_phrase, key_color=None,
                     subject_y=1.14, headline_y=1.03,
                     text_size=_TEXT_SIZE, key_size=_KEY_SIZE):
    """
    Two-level chart title above an axes:
      subject    – small grey overline, names the chart dimension
      grey_text  – headline context in grey (font-size 16 by default)
      key_phrase – ≤3-word key finding in accent color (font-size 18 by default, medium weight)

    Grey prefix and key phrase are rendered inline on the same baseline.
    Pass key_color to test an alternative to ACCENT without changing the project default.
    Pass subject_y/headline_y to raise the title block (e.g. to leave room for a
    legend row between the headline and the axes) without affecting other charts.
    Pass text_size/key_size to resize the headline for a specific chart (e.g. a
    wide multi-panel figure) without affecting other charts.
    Call this function after fig.subplots_adjust (needs final axes position); call plt.show() after.
    """
    key_color = key_color or ACCENT
    # Overline
    ax.text(0, subject_y, subject, transform=ax.transAxes,
            fontsize=_LABEL_SIZE, color=GREY_LABEL, va="baseline")

    # Grey part of headline — rendered first so we can measure its display width
    t_grey = ax.text(0, headline_y, grey_text + " ", transform=ax.transAxes,
                     fontsize=text_size, color=GREY_TEXT, fontweight="normal",
                     va="baseline")

    # Draw to get accurate bounding boxes
    ax.figure.canvas.draw()
    renderer = ax.figure.canvas.get_renderer()

    bb_txt = t_grey.get_window_extent(renderer=renderer)
    bb_ax  = ax.get_window_extent(renderer=renderer)
    x_key  = (bb_txt.x1 - bb_ax.x0) / bb_ax.width   # axes-fraction x after grey text

    # Orange key phrase immediately after grey text, same baseline
    ax.text(x_key, headline_y, key_phrase, transform=ax.transAxes,
            fontsize=key_size, color=key_color, fontweight="medium", va="baseline")
