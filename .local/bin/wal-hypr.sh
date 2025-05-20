#!/usr/bin/env bash
# Usage: wal-hypr.sh /path/to/new_wallpaper.png

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
 
# 9) Set spotify
# bash /home/chris/.config/spicetify/Themes/Pywal/update-colors.sh
# spicetify apply
