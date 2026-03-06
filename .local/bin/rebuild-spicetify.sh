#!/bin/bash
# Rebuild Spicetify after Spotify updates
# Called by pacman hook: /etc/pacman.d/hooks/99-rebuild-spicetify.hook

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==> Rebuilding Spicetify for updated Spotify...${NC}"

# Get current user (hook runs as root during package install)
REAL_USER="${SUDO_USER:-${USER}}"
REAL_HOME=$(eval echo ~"${REAL_USER}")

# Check if Spicetify is installed
if ! command -v spicetify &> /dev/null; then
    echo -e "${YELLOW}Warning: Spicetify not found, skipping rebuild${NC}"
    exit 0
fi

# Check if Spotify is installed
if ! pacman -Q spotify &> /dev/null; then
    echo -e "${YELLOW}Warning: Spotify not installed, skipping rebuild${NC}"
    exit 0
fi

# Run as the actual user (not root)
sudo -u "${REAL_USER}" bash -c "
    export HOME='${REAL_HOME}'

    echo -e '${YELLOW}  -> Restoring Spotify to clean state...${NC}'
    spicetify restore 2>/dev/null || true

    echo -e '${YELLOW}  -> Creating backup and applying Spicetify...${NC}'
    spicetify backup apply 2>&1 | tail -5

    if [ \$? -eq 0 ]; then
        echo -e '${GREEN}  -> Spicetify rebuilt successfully!${NC}'
    else
        echo -e '${RED}  -> Warning: Spicetify rebuild may have failed${NC}'
        echo -e '${YELLOW}     You may need to run manually: spicetify restore backup apply${NC}'
    fi
"

exit 0
