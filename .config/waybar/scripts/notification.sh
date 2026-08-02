#!/usr/bin/env bash
#
# notification.sh — mako state for waybar: unread count + do-not-disturb.
#
# Left click toggles do-not-disturb, right click dismisses everything.
#
# NOTE ON PARSING. `makoctl list` prints plain text in this mako version, not
# JSON, despite what several dotfile repos assume:
#
#     Notification 6: test
#       App name: notify-send
#       Urgency: normal
#
# Piping it to jq fails with "Invalid numeric literal". Counting lines that
# begin with "Notification " is the reliable read. If a future mako switches
# to JSON output, this grep returns 0 rather than erroring — the count would
# silently stick at zero, so re-check here if the badge stops moving.
set -uo pipefail

# Icon-to-value gap. A literal space is a full monospace cell, the same
# width as the gap between words, so the icon floated instead of binding to
# its value. Pango letter_spacing is ignored in these labels (GTK's CSS
# letter-spacing wins), but a space scaled with `size` does take effect.
# Keep this identical across every bar script — it is a consistency rule.
GAP="<span size='8704'> </span>"

ICON_NONE="󰂜"   # nf-md-bell-outline
ICON_SOME="󰂚"   # nf-md-bell
ICON_DND="󰂛"    # nf-md-bell-off

count=$(makoctl list 2>/dev/null | grep -c '^Notification ' || true)
modes=$(makoctl mode 2>/dev/null || true)

if grep -qx 'do-not-disturb' <<<"$modes"; then
    text="$ICON_DND"
    (( count > 0 )) && text="${ICON_DND}${GAP}${count}"
    printf '{"text":"%s","tooltip":"Do not disturb — %d waiting","class":"dnd"}\n' \
        "$text" "$count"
    exit 0
fi

if (( count > 0 )); then
    printf '{"text":"%s<span size='8704'> </span>%d","tooltip":"%d notification(s)","class":"unread"}\n' \
        "$ICON_SOME" "$count" "$count"
else
    printf '{"text":"%s","tooltip":"No notifications","class":"none"}\n' \
        "$ICON_NONE"
fi
