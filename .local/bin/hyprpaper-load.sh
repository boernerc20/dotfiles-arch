#!/usr/bin/env bash
# Hyprpaper wallpaper loader that handles symlinks
# Reads ~/.current_wallpaper and loads it via IPC

WALLPAPER=$(readlink -f ~/.current_wallpaper 2>/dev/null)

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "No valid wallpaper found at ~/.current_wallpaper"
    exit 1
fi

# Wait for hyprpaper to be ready (max 5 seconds).
# Uses `listactive`, NOT `listloaded`: hyprpaper 0.8.x dropped the
# preload/unload/listloaded IPC verbs, which now return "invalid hyprpaper
# request". The old listloaded probe therefore never succeeded and this loop
# always burned its full 5s timeout before continuing. Fixed 2026-07-30.
for i in {1..10}; do
    if hyprctl hyprpaper listactive &>/dev/null; then
        break
    fi
    sleep 0.5
done

# Set the wallpaper. `wallpaper` loads the image itself — no preload needed
# (and preload no longer exists, see above).
hyprctl hyprpaper wallpaper ",$WALLPAPER"

echo "Loaded wallpaper: $WALLPAPER"
