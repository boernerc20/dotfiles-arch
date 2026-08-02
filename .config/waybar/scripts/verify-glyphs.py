#!/usr/bin/env python3
"""Assert every Nerd Font glyph used by the bar actually renders.

Two distinct failure modes are checked, because both have already bitten:

1. STRIPPED GLYPHS. config.jsonc once shipped with
       "format-icons": ["", "", ""]
   — three EMPTY strings. Some editor or pipeline dropped the Private Use
   Area bytes. Nothing errored; the volume icon simply disappeared and the
   workspace indicator went blank, since format was "{icon}" and every icon
   resolved to "". An empty icon list is therefore an ERROR here, not a
   cosmetic detail.

2. MISSING COVERAGE. A codepoint that is present in the file but absent from
   the installed font renders as a tofu box. Cheaper to catch here than to
   notice on the bar.

Exit status is nonzero if either check fails, so this can gate a commit.

    ~/.config/waybar/scripts/verify-glyphs.py
"""
import json
import re
import sys
from pathlib import Path

try:
    from fontTools.ttLib import TTFont
except ImportError:
    sys.exit("fontTools not installed: pacman -S python-fonttools")

CONFIG_DIR = Path(__file__).resolve().parent.parent
FONT = Path("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf")

# Files that legitimately contain bar glyphs.
SOURCES = [CONFIG_DIR / "config.jsonc"] + sorted(
    (CONFIG_DIR / "scripts").glob("*.sh")
)

# Codepoints that are ordinary typography, not icons — ignore them.
IGNORE = set("─━—–…’“”°·•→│")

# The BMP Private Use Area. Glyphs here (Font Awesome, Devicons, nf-weather,
# nf-linux) render fine, so a cmap check alone passes them — but this is
# precisely the range that has been silently stripped from these files in
# transit, leaving empty strings behind. nf-md lives above U+F0000 and has
# always survived.
BMP_PUA = (0xE000, 0xF8FF)

# ...but the rule can only be ENFORCED where an nf-md equivalent exists.
# distro_icon.sh needs nf-linux distro logos and weather.sh needs nf-weather
# condition icons; neither set has an nf-md counterpart, so failing on them
# would mean a guard that cries wolf 29 times and gets ignored — which is
# worse than no guard. PUA use is therefore an ERROR in config.jsonc, the file
# that actually suffered the corruption and where nf-md alternatives exist,
# and a NOTE everywhere else.
PUA_ENFORCED = {"config.jsonc"}


def font_cmap(path):
    font = TTFont(str(path))
    cmap = set()
    for table in font["cmap"].tables:
        cmap |= set(table.cmap.keys())
    return cmap


def strip_jsonc(text):
    """Remove // comments so the file can be parsed as JSON."""
    return re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)


def check_empty_icons(path):
    """Catch the stripped-glyph regression: icon strings that are empty."""
    problems = []
    if path.suffix != ".jsonc":
        return problems
    try:
        data = json.loads(strip_jsonc(path.read_text(encoding="utf-8")))
    except json.JSONDecodeError as exc:
        problems.append(f"{path.name}: does not parse as JSON — {exc}")
        return problems

    def walk(node, trail):
        if isinstance(node, dict):
            for key, value in node.items():
                walk(value, f"{trail}.{key}" if trail else key)
        elif isinstance(node, list):
            for i, value in enumerate(node):
                walk(value, f"{trail}[{i}]")
        elif isinstance(node, str):
            # Any key whose name implies an icon must not be blank.
            if ("icon" in trail.lower() or trail.endswith("format")) and not node.strip():
                problems.append(f"{path.name}: {trail} is an EMPTY string")

    walk(data, "")
    return problems


def main():
    if not FONT.exists():
        sys.exit(f"font not found: {FONT}")

    cmap = font_cmap(FONT)
    missing = []
    empties = []
    risky = []

    for src in SOURCES:
        if not src.exists():
            continue
        empties += check_empty_icons(src)
        text = src.read_text(encoding="utf-8")
        for ch in text:
            if ord(ch) > 0x2000 and ch not in IGNORE:
                if ord(ch) not in cmap:
                    missing.append((src.name, ch))
                elif BMP_PUA[0] <= ord(ch) <= BMP_PUA[1]:
                    risky.append((src.name, ch))

    for problem in empties:
        print(f"EMPTY  {problem}")
    for name, ch in sorted(set(missing), key=lambda x: ord(x[1])):
        print(f"TOFU   {name}: U+{ord(ch):04X} not in {FONT.name}")
    fatal_pua = {(n, c) for n, c in risky if n in PUA_ENFORCED}
    noted_pua = {(n, c) for n, c in risky} - fatal_pua

    for name, ch in sorted(fatal_pua, key=lambda x: ord(x[1])):
        print(f"PUA    {name}: U+{ord(ch):04X} is in the BMP Private Use Area — "
              f"use an nf-md glyph (U+F0000+) instead")
    if noted_pua:
        by_file = {}
        for name, ch in noted_pua:
            by_file.setdefault(name, []).append(ch)
        summary = ", ".join(f"{n} ({len(v)})" for n, v in sorted(by_file.items()))
        print(f"note   PUA glyphs with no nf-md equivalent: {summary}")

    if empties or missing or fatal_pua:
        print(f"\nFAIL — {len(empties)} empty icon(s), "
              f"{len(set(missing))} missing glyph(s), "
              f"{len(fatal_pua)} PUA glyph(s) in {'/'.join(sorted(PUA_ENFORCED))}")
        return 1

    total = sum(
        1
        for src in SOURCES
        if src.exists()
        for ch in src.read_text(encoding="utf-8")
        if ord(ch) > 0x2000 and ch not in IGNORE
    )
    print(f"OK — {total} glyph occurrences, all present in {FONT.name}, no empty icons")
    return 0


if __name__ == "__main__":
    sys.exit(main())
