#!/usr/bin/env python3
"""Live network throughput as a coloured sparkline for waybar.

Replaces a numeric down/up readout. Two right-aligned figures plus a unit was
a lot of glyphs for "is the network busy", and the digits churned constantly
even after the width was pinned. A sparkline answers the same question with no
moving text, is fixed-width by construction, and reads as an instrument.

Design notes
------------
* CONTINUOUS, not interval. waybar re-execs an `interval` script every tick,
  which would mean serialising 14 samples of history to disk and back every
  second. This runs as a persistent process and keeps history in memory; the
  module declares `restart-interval` so waybar revives it if it ever dies.

* LOG SCALE. Linear scaling makes everything below a megabyte look identical
  to idle, so ordinary browsing would render as a flat line. Log makes the
  difference between 2 kB/s and 200 kB/s visible, which is the range actually
  lived in.

* BLOCK GLYPHS ARE NOT PRIVATE USE AREA. U+2581-2588 are standard Unicode, so
  they are immune to the PUA-stripping problem that emptied the icon strings
  in config.jsonc. Only the leading status icon is a Nerd Font glyph.

* Colour comes from the palette via Pango markup, so the sparkline re-tints
  with the wallpaper. The palette is read once at start: wal-hypr.sh restarts
  waybar on every wallpaper change, which restarts this script.
"""
import html
import json
import os
import sys
import time

IFACE = sys.argv[1] if len(sys.argv) > 1 else "enp7s0"

BLOCKS = "▁▂▃▄▅▆▇█"
CELLS = 14
PERIOD = 1.0

# Upper reference for the log scale, in kB/s. Traffic above this pins the bar
# at full height rather than rescaling the whole history, so the sparkline
# stays comparable moment to moment instead of silently changing its own units.
SCALE_MAX_KBPS = 12000.0

ICON = "󰓅"          # nf-md-speedometer
ICON_OFF = "󰈂"      # nf-md-lan-disconnect

COLORS = os.path.expanduser("~/.cache/wal/colors.json")
SYSFS = f"/sys/class/net/{IFACE}"


def load_palette():
    """Cool colour for quiet, hot colour for busy. Falls back if unreadable."""
    try:
        with open(COLORS) as f:
            c = json.load(f)["colors"]
        return c["color8"], c["color6"], c["color2"]
    except Exception:
        return "#555555", "#5FD8E9", "#CA4CBD"


def _rgb(h):
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def blend(a, b, t):
    ra, ga, ba = _rgb(a)
    rb, gb, bb = _rgb(b)
    return "#{:02x}{:02x}{:02x}".format(
        int(ra + (rb - ra) * t), int(ga + (gb - ga) * t), int(ba + (bb - ba) * t)
    )


def read_counters():
    try:
        with open(f"{SYSFS}/statistics/rx_bytes") as f:
            rx = int(f.read())
        with open(f"{SYSFS}/statistics/tx_bytes") as f:
            tx = int(f.read())
        return rx, tx
    except OSError:
        return None, None


def is_up():
    try:
        with open(f"{SYSFS}/operstate") as f:
            return f.read().strip() == "up"
    except OSError:
        return False


def level(kbps):
    """Map kB/s to a 0..7 block index on a log curve."""
    import math

    if kbps <= 0.05:
        return 0
    frac = math.log1p(kbps) / math.log1p(SCALE_MAX_KBPS)
    return max(0, min(len(BLOCKS) - 1, int(frac * (len(BLOCKS) - 1) + 0.5)))


def human(kbps):
    if kbps >= 1024:
        return f"{kbps / 1024:.1f} MB/s"
    return f"{kbps:.1f} kB/s"


def emit(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def main():
    dim, cool, hot = load_palette()
    history = [0.0] * CELLS
    rx_prev = tx_prev = None
    t_prev = time.monotonic()

    while True:
        if not is_up():
            emit({
                "text": f"{ICON_OFF} {'─' * CELLS}",
                "tooltip": f"{IFACE} is down",
                "class": "disconnected",
            })
            rx_prev = tx_prev = None
            time.sleep(PERIOD)
            continue

        rx, tx = read_counters()
        now = time.monotonic()

        if rx is None:
            time.sleep(PERIOD)
            continue

        if rx_prev is None:
            # Seed. Reporting a delta against an uninitialised baseline would
            # render the machine's entire uptime as one enormous first spike.
            rx_prev, tx_prev, t_prev = rx, tx, now
            time.sleep(PERIOD)
            continue

        elapsed = now - t_prev or PERIOD
        # Counters can go backwards if the interface is bounced; clamp so a
        # reset shows as idle rather than as a negative-turned-huge spike.
        d_rx = max(0, rx - rx_prev) / 1024 / elapsed
        d_tx = max(0, tx - tx_prev) / 1024 / elapsed
        rx_prev, tx_prev, t_prev = rx, tx, now

        history.append(d_rx + d_tx)
        del history[:-CELLS]

        spark = []
        for v in history:
            lv = level(v)
            t = lv / (len(BLOCKS) - 1)
            colour = blend(dim, cool, t * 2) if t < 0.5 else blend(cool, hot, (t - 0.5) * 2)
            spark.append(f'<span color="{colour}">{BLOCKS[lv]}</span>')

        peak = max(history)
        emit({
            "text": f"{ICON} " + "".join(spark),
            "tooltip": html.escape(
                f"{IFACE}\n"
                f"Down  {human(d_rx)}\n"
                f"Up    {human(d_tx)}\n"
                f"Peak  {human(peak)}  (last {CELLS}s)"
            ),
            "class": "connected",
        })
        time.sleep(PERIOD)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
