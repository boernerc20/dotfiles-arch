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

# 1) Generate the new palette.
#
# wallust replaced python-pywal on 2026-07-31 (Phase 5). It renders into
# ~/.cache/wal/ using pywal's OWN filenames, so every consumer below — waybar,
# kitty, rofi, cava, yazi, firefox, ~/.config/wal/postrun — is unchanged.
# Config: ~/.config/wallust/wallust.toml
#
# Do NOT put `wal -i` back here. pywal and wallust write the same paths, so a
# stray `wal -i` silently reverts the whole system to the old engine on the
# next wallpaper change.
if command -v wallust &>/dev/null; then
    wallust run -q "$WP"
else
    echo "ERROR: wallust not found — cannot generate palette. Aborting." >&2
    exit 1
fi

# 2) Set the wallpaper on all monitors.
# NOTE: the old `hyprctl hyprpaper preload` call was removed 2026-07-30 — hyprpaper
# 0.8.x dropped the preload/unload/listloaded IPC verbs and they now return
# "error: invalid hyprpaper request". `wallpaper` loads the image itself, so the
# preload step was both broken and unnecessary.
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

# 7) Link firefox home page stylesheets (only if the profile dir exists).
# Both are SYMLINKS into ~/.cache/wal, so they update themselves whenever the
# palette is regenerated. The old unconditional cp errored with "are the same
# file" on every run; -f + -n replaces a stale link without following it.
#
# surfaces.css carries the canonical app surface ramp (see ~/.config/wal/postrun)
# and is what keeps the start page on the same background as native apps. If it
# is missing the page silently falls back to whatever colors.css provides, so
# the link is re-established every run rather than only at install time.
if [ -d "$HOME/.config/firefox/home" ]; then
    for sheet in colors.css surfaces.css; do
        if [ -e "$HOME/.cache/wal/$sheet" ]; then
            ln -sfn "$HOME/.cache/wal/$sheet" "$HOME/.config/firefox/home/$sheet"
        fi
    done
fi

# 8) Set rofi — symlink current wallpaper for the template's background-image,
# then install the freshly rendered theme.
ln -sf "$WP" "$HOME/.config/rofi/img/current.png"
cp "$HOME/.cache/wal/colors-rofi.rasi" "$HOME/.config/rofi/colors-rofi.rasi"

# 9) Record the current wallpaper (hyprlock + rofi templates both read this)
ln -sf "$WP" "$HOME/.current_wallpaper"

# 9a) Notifications — mako has no live-reload of colors, so install the newly
# rendered config and tell the running daemon to re-read it.
if [ -f "$HOME/.cache/wal/mako-config" ]; then
    cp "$HOME/.cache/wal/mako-config" "$HOME/.config/mako/config"
    makoctl reload 2>/dev/null || echo "Warning: makoctl reload failed (is mako running?)" >&2
fi

# 9b) Hyprland window-border colors. Copied to a REAL file under conf.d/ rather
# than sourced out of the cache: hyprland.conf sources 09-colors.conf
# unconditionally, so a missing/half-written cache file would be a config error
# on every reload. A copy always holds the last known-good palette.
# Hyprland auto-reloads on write, so the borders update with no explicit reload.
if [ -f "$HOME/.cache/wal/hypr-colors.conf" ]; then
    cp "$HOME/.cache/wal/hypr-colors.conf" "$HOME/.config/hypr/conf.d/09-colors.conf"
fi

# 10) Set hyprlock (pywal renders the template to ~/.cache/wal/hyprlock.conf;
# copy it to a real file so a broken wal cache can never break the locker)
if [ -f "$HOME/.cache/wal/hyprlock.conf" ]; then
    cp "$HOME/.cache/wal/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
else
    echo "Warning: ~/.cache/wal/hyprlock.conf not rendered, keeping existing hyprlock.conf" >&2
fi

# 11) Animated ASCII
if [ -x "$HOME/.config/neofetch/recolor_from_wal.py" ]; then
    "$HOME/.config/neofetch/recolor_from_wal.py"
else
    echo "Warning: ~/.config/neofetch/recolor_from_wal.py not found or not executable, skipping neofetch theming" >&2
fi

# 12) Set yazi
if [ -x "$HOME/.local/bin/yazi-pywal-update.sh" ]; then
    "$HOME/.local/bin/yazi-pywal-update.sh"
else
    echo "Warning: ~/.local/bin/yazi-pywal-update.sh not found or not executable, skipping yazi theming" >&2
fi
