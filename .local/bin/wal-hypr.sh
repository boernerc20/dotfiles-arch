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

# 5) Apply to cava
if [ -x "$HOME/.local/bin/wal-cava.sh" ]; then
    "$HOME/.local/bin/wal-cava.sh"
else
    echo "Warning: ~/.local/bin/wal-cava.sh not found or not executable, skipping cava theming" >&2
fi

# 6) Apply to firefox
if command -v pywalfox &>/dev/null; then
    pywalfox update
else
    echo "Warning: pywalfox not found, skipping Firefox theming" >&2
fi

# 7) Link firefox home page (only if the profile dir exists)
if [ -d "$HOME/.config/firefox/home" ]; then
    cp ~/.cache/wal/colors.css ~/.config/firefox/home/colors.css
fi

# 8) Set rofi — symlink current wallpaper for the template's background-image,
# then install the freshly rendered theme.
ln -sf "$WP" "$HOME/.config/rofi/img/current.png"
cp "$HOME/.cache/wal/colors-rofi.rasi" "$HOME/.config/rofi/colors-rofi.rasi"

# 9) Set hyprlock
ln -sf "$WP" "$HOME/.current_wallpaper"

# 10) Animated ASCII
if [ -x "$HOME/.config/neofetch/recolor_from_wal.py" ]; then
    "$HOME/.config/neofetch/recolor_from_wal.py"
else
    echo "Warning: ~/.config/neofetch/recolor_from_wal.py not found or not executable, skipping neofetch theming" >&2
fi

# 11) Set yazi
if [ -x "$HOME/.local/bin/yazi-pywal-update.sh" ]; then
    "$HOME/.local/bin/yazi-pywal-update.sh"
else
    echo "Warning: ~/.local/bin/yazi-pywal-update.sh not found or not executable, skipping yazi theming" >&2
fi
