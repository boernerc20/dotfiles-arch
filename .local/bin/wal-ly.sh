#!/bin/bash
# Update ly login manager colors from pywal
# This script reads pywal colors and updates /etc/ly/config.ini

# Check if pywal colors exist
if [ ! -f "$HOME/.cache/wal/colors" ]; then
    echo "Error: pywal colors not found at $HOME/.cache/wal/colors"
    exit 1
fi

# Read pywal colors
color0=$(sed -n '1p' "$HOME/.cache/wal/colors" | sed 's/#//')   # background
color1=$(sed -n '2p' "$HOME/.cache/wal/colors" | sed 's/#//')   # dark accent
color4=$(sed -n '5p' "$HOME/.cache/wal/colors" | sed 's/#//')   # bright accent
color7=$(sed -n '8p' "$HOME/.cache/wal/colors" | sed 's/#//')   # foreground

# Convert to ly format (0x00RRGGBB for colors, 0x01RRGGBB for bold)
bg="0x00${color0}"
fg="0x00${color7}"
border_fg="0x00${color4}"
error_fg="0x01${color1}"

# Update ly config with sudo
sudo sed -i "s/^bg = .*/bg = ${bg}/" /etc/ly/config.ini
sudo sed -i "s/^fg = .*/fg = ${fg}/" /etc/ly/config.ini
sudo sed -i "s/^border_fg = .*/border_fg = ${border_fg}/" /etc/ly/config.ini
sudo sed -i "s/^error_fg = .*/error_fg = ${error_fg}/" /etc/ly/config.ini

echo "ly colors updated with pywal theme:"
echo "  bg (background): ${bg} (${color0})"
echo "  fg (foreground): ${fg} (${color7})"
echo "  border_fg:       ${border_fg} (${color4})"
echo "  error_fg:        ${error_fg} (${color1})"
