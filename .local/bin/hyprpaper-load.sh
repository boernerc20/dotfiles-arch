#!/usr/bin/env bash
# Hyprpaper wallpaper loader that handles symlinks
# Reads ~/.current_wallpaper and loads it via IPC

WALLPAPER=$(readlink -f ~/.current_wallpaper 2>/dev/null)

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "No valid wallpaper found at ~/.current_wallpaper"
    exit 1
fi

# Wait for hyprpaper to be ready (max 5 seconds)
for i in {1..10}; do
    if hyprctl hyprpaper listloaded &>/dev/null; then
        break
    fi
    sleep 0.5
done

# Preload and set the wallpaper
hyprctl hyprpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper ",$WALLPAPER"

echo "Loaded wallpaper: $WALLPAPER"
