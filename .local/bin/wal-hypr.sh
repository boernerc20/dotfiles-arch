#!/usr/bin/env bash
# Usage: wal-hypr.sh /path/to/new_wallpaper.png

# Lockfile to prevent concurrent runs
LOCKFILE="/tmp/wal-hypr.lock"
if [ -e "$LOCKFILE" ]; then
    echo "Another instance is running, skipping..."
    exit 0
fi
trap "rm -f $LOCKFILE" EXIT
touch "$LOCKFILE"

WP="$1"
if [[ -z "$WP" || ! -f "$WP" ]]; then
  echo "Usage: $0 /path/to/image.png"
  exit 1
fi

# 1) Generate new Wal palette
wal -i "$WP"

# 2) Tell Hyprpaper to preload the image
hyprctl hyprpaper preload "$WP"

# 3) Set it on all monitors
hyprctl hyprpaper wallpaper ",$WP"

# 4) Set waybar
cat ~/.cache/wal/colors-waybar.css ~/.config/waybar/style-base.css > ~/.config/waybar/style.css
# Restart waybar to apply new colors (kill + restart avoids reload segfaults)
if pgrep -x waybar > /dev/null; then
    killall -q waybar
    # Brief wait to ensure clean shutdown
    sleep 0.3
    waybar &>/dev/null &
    disown
fi

# 5) Apply to new terminals
/home/chris/.local/bin/wal-ala.sh

# 6) Apply to cava
/home/chris/.local/bin/wal-cava.sh

# 7) Apply to firefox
pywalfox update

# 8) Link firefox home page
cp ~/.cache/wal/colors.css ~/.config/firefox/home/colors.css

# 9) Set rofi
bash /home/chris/.local/bin/wal-rofi.sh "$WP"

# 10) Set hyprlock
ln -sf "$WP" "$HOME/.current_wallpaper"

# 12) Animated ASCII
/home/chris/.config/neofetch/recolor_from_wal.py

# 13) Set yazi
/home/chris/.local/bin/yazi-pywal-update.sh

# 14) Update ly login manager colors
/home/chris/.local/bin/wal-ly.sh

# 15) Set spotify
# Check if Spotify is running before updating
SPOTIFY_WAS_RUNNING=false
if pgrep -x spotify > /dev/null; then
    SPOTIFY_WAS_RUNNING=true
fi

# Update colors and apply theme (quiet mode)
if bash /home/chris/.config/spicetify/Themes/Pywal/update-colors.sh true 2>/dev/null; then
    # Only apply if color update succeeded
    spicetify apply 2>/dev/null || true

    # Restart Spotify to apply new theme (only if it was already running)
    if [ "$SPOTIFY_WAS_RUNNING" = true ]; then
        # Kill all Spotify processes
        killall -q spotify 2>/dev/null || true
        sleep 0.5
        # Restart Spotify in background, detached from terminal
        nohup spotify &>/dev/null &
        disown
    fi
else
    # Color update failed, skip Spotify theming but don't fail the whole script
    echo "Warning: Failed to update Spotify colors" >&2
fi
