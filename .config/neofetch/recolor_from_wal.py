#!/usr/bin/env python3
"""
Recolor truecolor ANSI in frames_src -> frames_colour using CURRENT pywal palette
(only reads ~/.cache/wal/colors.sh; no hardcoded hex).

Mapping strategy:
- Keep very dark (value < ~0.12) and very low-saturation (~<0.12) colors as-is.
- Hue buckets route to three live wal tones:
    A := env["color6"]  (often teal/cyan)
    B := env["color5"]  (often mauve/purple)
    C := env["color4"]  (often slate/indigo)
- Optional FORCE table lets you pin specific source shades to A/B/C if needed.
"""
import os, re, colorsys, sys

HOME = os.path.expanduser("~")
SRC = os.path.join(HOME, ".config/neofetch/frames_src")
OUT = os.path.join(HOME, ".config/neofetch/frames_colour")
WAL = os.path.join(HOME, ".cache/wal/colors.sh")

rgb_pat_fg = re.compile(r"\x1b\[38;2;(\d+);(\d+);(\d+)m")
rgb_pat_bg = re.compile(r"\x1b\[48;2;(\d+);(\d+);(\d+)m")

def hex2rgb(h):
    h = h.strip().lstrip("#")
    if len(h) != 6:
        raise ValueError(f"Bad hex '{h}' from wal")
    return tuple(int(h[i:i+2], 16) for i in (0,2,4))

def esc_fg(rgb): return f"\x1b[38;2;{rgb[0]};{rgb[1]};{rgb[2]}m"
def esc_bg(rgb): return f"\x1b[48;2;{rgb[0]};{rgb[1]};{rgb[2]}m"

# Load ONLY from wal colors.sh (no hardcoded hex defaults)
if not os.path.isfile(WAL):
    print(f"Missing {WAL}", file=sys.stderr); sys.exit(1)

env = {}
with open(WAL, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        line = line.strip()
        if not line or "=" not in line: 
            continue
        k, v = line.split("=", 1)
        k = k.strip()
        v = v.strip().strip("'").strip('"')
        if k.startswith(("color", "foreground", "background")):
            env[k] = v

for key in ("color4", "color5", "color6"):
    if key not in env:
        print(f"{key} missing in {WAL}", file=sys.stderr); sys.exit(1)

# Live palette trio from wal
A = hex2rgb(env["color6"])  # highlight
B = hex2rgb(env["color5"])  # secondary
C = hex2rgb(env["color4"])  # ambient

# Optional: pin specific source shades to A/B/C, if you know them
FORCE = {
    # Example: (R,G,B,"fg"): "A"
    # (235,197,126,"fg"): "A",
}

def choose_key(rgb):
    r,g,b = (c/255.0 for c in rgb)
    h,s,v = colorsys.rgb_to_hsv(r,g,b)   # h∈[0,1)
    H = h*360.0

    # Preserve dark ink and low-sat greys
    if v < 0.12:  # very dark
        return None
    if s < 0.12:  # grey-ish
        return None

    # Hue routing (tweak ranges if needed)
    if 15.0 <= H <= 80.0:    # orange/gold/brown
        return "A"
    if 180.0 <= H <= 260.0:  # blue/cyan
        return "C"
    if 260.0 <= H <= 340.0:  # purple/magenta
        return "B"

    if H < 15.0 or H > 340.0:  # reds
        return "B"
    if 80.0 < H < 180.0:       # greens/teals
        return "A"

    return "B"

def recolor(text):
    def sub(kind, m):
        rgb = tuple(map(int, m.groups()))
        forced = FORCE.get((rgb, kind))
        if forced:
            tgt = {"A":A, "B":B, "C":C}[forced]
            return esc_fg(tgt) if kind == "fg" else esc_bg(tgt)

        key = choose_key(rgb)
        if key is None:
            return m.group(0)  # keep original escape
        tgt = {"A":A, "B":B, "C":C}[key]
        return esc_fg(tgt) if kind == "fg" else esc_bg(tgt)

    text = rgb_pat_fg.sub(lambda m: sub("fg", m), text)
    text = rgb_pat_bg.sub(lambda m: sub("bg", m), text)
    return text

os.makedirs(OUT, exist_ok=True)

count = 0
for fn in sorted(os.listdir(SRC)):
    if not fn.endswith(".txt"): 
        continue
    p = os.path.join(SRC, fn)
    with open(p, "rb") as fh:
        raw = fh.read().decode("utf-8", errors="ignore")
    out = recolor(raw)
    with open(os.path.join(OUT, fn), "w", encoding="utf-8") as fw:
        fw.write(out)
    count += 1

print(f"Recolored {count} frame(s) -> {OUT}")
