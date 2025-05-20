#!/usr/bin/env bash
#
# Simple Wal-Powered Rofi Power Menu for Hyprland
# Uses your Wal-generated theme at ~/.cache/wal/colors-rofi-power.rasi
# Lock screen uses ~/.cache/wal/colors-hyprland.conf

THEME="$HOME/.cache/wal/colors-rofi-power.rasi"
HYPRCONF="$HOME/.cache/wal/colors-hyprland.conf"
uptime="$(uptime -p | sed 's/up //')"

# Icons
shutdown=''
reboot='󰜉'
lock=''
suspend=''
logout='󰗽'

# Show the menu and capture selection
chosen="$(printf "%s\n%s\n%s\n%s\n%s" \
    "$lock" "$suspend" "$logout" "$reboot" "$shutdown" \
  | rofi -dmenu \
         -p "Goodbye $USER" \
         -mesg "Uptime: $uptime" \
         -config "$THEME")"

# Dispatch immediately—no confirmation
case "$chosen" in
  "$shutdown")   systemctl poweroff     ;;
  "$reboot")     systemctl reboot       ;;
  "$suspend")    systemctl suspend      ;;
  "$logout")     hyprctl dispatch exit  ;;
  "$lock")       hyprlock --config "$HYPRCONF" ;;
esac
