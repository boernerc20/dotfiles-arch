#!/bin/bash
# ── animated-neofetch.sh ────────────────────────────────
# Description: Animated ASCII frames + cached neofetch/fastfetch system info
# Usage: ./animated-neofetch.sh [delay]

delay=${1:-0.1}
ascii_row=1
ascii_col=1
text_col=60

cache_file="$HOME/.cache/neofetch.txt"
palette="$HOME/.cache/wal/colors.sh"
src_dir="$HOME/.config/neofetch/frames_src"
out_dir="$HOME/.config/neofetch/frames_colour"
stamp="$out_dir/.palette-stamp"

mkdir -p "$HOME/.cache" "$out_dir"

# Build/refresh the text block (unchanged)
if [[ ! -f "$cache_file" || $(find "$cache_file" -mmin +60 2>/dev/null) ]]; then
  if command -v fastfetch >/dev/null 2>&1; then
    fastfetch --logo none > "$cache_file"
  else
    neofetch --disable ascii > "$cache_file"
  fi
fi

# ── NEW: recolor frames from current wal palette (only when palette changes)
if [[ ! -s "$palette" ]]; then
  echo "wal colors.sh not found at $palette"; exit 1
fi
if [[ ! -d "$src_dir" ]]; then
  echo "frames_src not found at $src_dir"; exit 1
fi
if [[ ! -f "$stamp" || "$palette" -nt "$stamp" ]]; then
  python3 "$HOME/.config/neofetch/recolor_from_wal.py" || exit 1
  cp -f "$palette" "$stamp" 2>/dev/null || touch "$stamp"
fi

clear
tput cup $ascii_row $text_col
cat "$cache_file"

tput civis
trap 'tput cnorm; exit' INT TERM

# Play the recolored frames
while true; do
  for frame in "$out_dir"/*.txt; do
    tput cup $ascii_row $ascii_col
    cat "$frame"
    # Wait a little, but also check if user pressed a key
    read -t $delay -n 1 key && { tput cnorm; exit; }
  done
done
