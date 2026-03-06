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
    sleep 0.3
    waybar &>/dev/null &
    disown
fi

# 5) Apply to new terminals
"$HOME/.local/bin/wal-ala.sh"

# 6) Apply to cava
"$HOME/.local/bin/wal-cava.sh"

# 7) Apply to firefox
pywalfox update

# 8) Link firefox home page
cp ~/.cache/wal/colors.css ~/.config/firefox/home/colors.css

# 9) Set rofi
bash "$HOME/.local/bin/wal-rofi.sh" "$WP"

# 10) Set hyprlock
ln -sf "$WP" "$HOME/.current_wallpaper"

# 11) Animated ASCII
"$HOME/.config/neofetch/recolor_from_wal.py"

# 12) Set yazi
"$HOME/.local/bin/yazi-pywal-update.sh"

# 13) Update ly login manager colors
"$HOME/.local/bin/wal-ly.sh"

# 14) Set spotify
SPOTIFY_WAS_RUNNING=false
if pgrep -x spotify > /dev/null; then
    SPOTIFY_WAS_RUNNING=true
fi

if bash "$HOME/.config/spicetify/Themes/Pywal/update-colors.sh" true 2>/dev/null; then
    spicetify apply 2>/dev/null || true

    if [ "$SPOTIFY_WAS_RUNNING" = true ]; then
        killall -q spotify 2>/dev/null || true
        sleep 0.5
        nohup spotify &>/dev/null &
        disown
    fi
else
    echo "Warning: Failed to update Spotify colors" >&2
fi
