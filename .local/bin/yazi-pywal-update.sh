#!/bin/bash
# Yazi Pywal Theme Updater
# Symlinks the pywal-generated theme to yazi's theme directory
# This script is called by wal-hypr.sh when wallpaper changes

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
PYWAL_THEME="/home/chris/.cache/wal/yazi-theme.toml"
YAZI_THEME_DIR="/home/chris/.config/yazi"
YAZI_THEME="${YAZI_THEME_DIR}/theme.toml"

# Check if pywal theme was generated
if [[ ! -f "$PYWAL_THEME" ]]; then
    echo -e "${YELLOW}Warning: Pywal theme not found at $PYWAL_THEME${NC}"
    echo "Run 'wal -i <wallpaper>' to generate it"
    exit 1
fi

# Create yazi config directory if it doesn't exist
mkdir -p "$YAZI_THEME_DIR"

# Create symlink (remove old one if exists)
rm -f "$YAZI_THEME"
ln -sf "$PYWAL_THEME" "$YAZI_THEME"

echo -e "${GREEN}Yazi theme updated successfully${NC}"
