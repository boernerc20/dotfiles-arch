#!/usr/bin/env bash
# brightness.sh — monitor backlight percentage for waybar.
#
# Reads the external monitor's REAL backlight over DDC/CI (see
# ~/.local/bin/monitor-brightness for why /sys/class/backlight is empty on this
# machine and brightnessctl cannot work here).
#
# WIDTH IS PINNED IN CSS. Brightness spans 0-100%, so the digit count swings
# between 1 and 3 and the pill would resize as it changed — the same jitter the
# hardware module had. #custom-brightness is clamped to a fixed 85px in
# style-base.css rather than padded here; see hardware.sh for why.
#
# CACHING. A DDC read costs ~330ms and waybar blocks its whole update on an exec
# script, so polling it directly would stall the bar. monitor-brightness writes
# the value to a cache file on every change; this reads that file when it is
# fresh and only falls back to a real DDC read when it is stale or missing.
set -uo pipefail

CACHE="${XDG_RUNTIME_DIR:-/tmp}/ddc-brightness-value"
ICON="󰃟"
GAP="<span size='8704'> </span>"

# NO PADDING. The format is exactly `icon + GAP + value`, identical to the
# pulseaudio, disk and weather pills — those are the reference for what a module
# on this bar looks like, and none of them pad. An earlier version padded the
# value to a fixed 3 characters to stop the pill resizing; it worked, but it
# made this pill visibly wider and more spaced-out than its neighbours, which is
# a worse problem than the resize it solved. Volume moves between 5% and 100%
# the same way and is simply allowed to.

# Considered fresh for 60s. Anything changed through the keybinds refreshes the
# cache immediately, so this only bounds how long an out-of-band change (the
# monitor's own OSD buttons) can go unnoticed.
MAX_AGE=60

read_cache() {
    [[ -r "$CACHE" ]] || return 1
    local age now mtime v
    now=$(date +%s)
    mtime=$(stat -c %Y "$CACHE" 2>/dev/null) || return 1
    age=$(( now - mtime ))
    (( age > MAX_AGE )) && return 1
    v=$(<"$CACHE")
    [[ "$v" =~ ^[0-9]+$ ]] || return 1
    echo "$v"
}

value=$(read_cache) || {
    value=$(~/.local/bin/monitor-brightness get 2>/dev/null)
    if [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "$value" > "$CACHE"
    else
        # DDC unavailable — monitor off, unplugged, or DDC/CI disabled in its
        # OSD. Emit a dash rather than a stale or zero number. The trailing "%"
        # is kept even though there is no number: dropping it made this state
        # one cell narrower than every real reading, so the bar would shift at
        # exactly the moment something was already going wrong.
        printf '%s%s--%%\n' "$ICON" "$GAP"
        exit 0
    fi
}

printf '%s%s%s%%\n' "$ICON" "$GAP" "$value"
