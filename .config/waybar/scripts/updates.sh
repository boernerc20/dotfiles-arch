#!/usr/bin/env bash
#
# updates.sh — pending package count for waybar, official repos + AUR.
#
# Updates on this system are deliberately manual (yay -Syu) for visibility,
# which means nothing otherwise tells you they are waiting. This does.
#
# No `set -e`: both checkupdates and yay exit nonzero for the perfectly normal
# "nothing to update" case, and yay additionally fails whenever the network is
# down. An error here must degrade to a quiet zero, never to a broken module.
set -uo pipefail

# Icon-to-value gap. A literal space is a full monospace cell, the same
# width as the gap between words, so the icon floated instead of binding to
# its value. Pango letter_spacing is ignored in these labels (GTK's CSS
# letter-spacing wins), but a space scaled with `size` does take effect.
# Keep this identical across every bar script — it is a consistency rule.
GAP="<span size='8704'> </span>"

ICON_PENDING="󰚰"   # nf-md-sync
ICON_CURRENT="󰄬"   # nf-md-check

# checkupdates syncs into its own temporary database, so it never touches the
# real pacman DB and never needs root. Using `pacman -Sy` here instead would
# risk a partial-upgrade state.
repo_list=$(checkupdates 2>/dev/null || true)
aur_list=$(yay -Qua 2>/dev/null || true)

repo_count=$(printf '%s' "$repo_list" | grep -c . || true)
aur_count=$(printf '%s' "$aur_list" | grep -c . || true)
total=$(( repo_count + aur_count ))

if (( total == 0 )); then
    printf '{"text":"%s","tooltip":"System is up to date","class":"current"}\n' \
        "$ICON_CURRENT"
    exit 0
fi

# Build the tooltip with jq so package names containing quotes or backslashes
# cannot break the JSON waybar parses.
tooltip=$(
    {
        printf '%d official, %d AUR\n\n' "$repo_count" "$aur_count"
        [[ -n $repo_list ]] && printf '%s\n' "$repo_list"
        [[ -n $aur_list  ]] && printf '%s\n' "$aur_list"
    } | head -40
)

jq -cn \
    --arg text "${ICON_PENDING}${GAP}${total}" \
    --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip, class: "pending"}'
