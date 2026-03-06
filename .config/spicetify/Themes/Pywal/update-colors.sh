#!/bin/bash
# Update Spicetify Pywal theme colors from pywal color scheme
# This script generates a text-theme compatible color.ini from pywal colors

set -e  # Exit on error

PYWAL_COLORS="$HOME/.cache/wal/colors.sh"
SPICETIFY_THEME_DIR="$HOME/.config/spicetify/Themes/Pywal"
COLOR_INI="$SPICETIFY_THEME_DIR/color.ini"
QUIET="${1:-false}"

# Check if pywal colors exist
if [[ ! -f "$PYWAL_COLORS" ]]; then
    echo "Error: Pywal colors not found at $PYWAL_COLORS"
    echo "Please run 'wal -i /path/to/wallpaper' first"
    exit 1
fi

# Source pywal colors
source "$PYWAL_COLORS"

# Remove # from colors
bg="${background#\#}"
fg="${foreground#\#}"
c0="${color0#\#}"
c1="${color1#\#}"
c2="${color2#\#}"
c3="${color3#\#}"
c4="${color4#\#}"
c5="${color5#\#}"
c6="${color6#\#}"
c7="${color7#\#}"
c8="${color8#\#}"

# Generate color.ini with text theme format
cat > "$COLOR_INI" << EOF
; Pywal colors for Spicetify text theme
; Auto-generated from pywal colors
; Wallpaper: $wallpaper

[Pywal]
accent             = $c4
accent-active      = $c6
accent-inactive    = $bg
banner             = $c6
border-active      = $c6
border-inactive    = $c8
header             = $c8
highlight          = $c8
main               = $bg
notification       = $c4
notification-error = $c1
subtext            = $c7
text               = $fg
EOF

if [ "$QUIET" != "true" ]; then
    echo "✓ Generated color.ini from pywal colors"
    echo "  Background: #$bg"
    echo "  Foreground: #$fg"
    echo "  Accent: #$c4"
    echo ""
    echo "Run 'spicetify apply' to apply changes"
fi

# Always exit successfully if we got this far
exit 0
