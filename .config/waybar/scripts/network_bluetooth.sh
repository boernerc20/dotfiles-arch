#!/usr/bin/env bash

### Wi-Fi Signal Strength (via nmcli)
wifi_icon="󰤟"  # default (no signal)

wifi_info=$(nmcli -t -f ACTIVE,SIGNAL dev wifi | grep '^yes:' || true)
if [[ -n "$wifi_info" ]]; then
  signal=$(echo "$wifi_info" | cut -d: -f2)
  if   (( signal < 25 )); then wifi_icon="󰤟"
  elif (( signal < 50 )); then wifi_icon="󰤢"
  elif (( signal < 75 )); then wifi_icon="󰤥"
  else                        wifi_icon="󰤨"
  fi
fi

### Bluetooth State (via bluetoothctl)
bt_icon="󰂱"  # default: service not running

if systemctl is-active --quiet bluetooth.service; then
  bt_powered=$(bluetoothctl show | awk '/Powered:/ {print $2}')
  if [[ "$bt_powered" == "yes" ]]; then
    bt_connected=$(bluetoothctl info | grep -q 'Connected: yes' && echo "yes" || echo "no")
    if [[ "$bt_connected" == "yes" ]]; then
      bt_icon="󰂲"
    else
      bt_icon="󰂯"
    fi
  fi
fi

### Output only icons (for Waybar)
echo "$wifi_icon $bt_icon"
