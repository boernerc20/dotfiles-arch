#!/usr/bin/env bash

### Detect active network interface
iface=$(ip route | awk '/default/ {print $5}' | head -n1)

wifi_icon=""
wired_icon="󰈀"  # Ethernet icon

### Check if interface is Wi-Fi
if [[ -n "$iface" && "$iface" =~ ^wl ]]; then
  # Wi-Fi connection
  wifi_info=$(nmcli -t -f ACTIVE,SIGNAL dev wifi | grep '^yes:' || true)
  if [[ -n "$wifi_info" ]]; then
    signal=$(echo "$wifi_info" | cut -d: -f2)
    if   (( signal < 25 )); then wifi_icon="󰤟"   # weak
    elif (( signal < 50 )); then wifi_icon="󰤢"   # fair
    elif (( signal < 75 )); then wifi_icon="󰤥"   # good
    else                        wifi_icon="󰤨"   # excellent
    fi
  else
    wifi_icon="󰤮"  # no signal / not connected
  fi
  net_icon="$wifi_icon"
elif [[ -n "$iface" && "$iface" =~ ^en ]]; then
  # Ethernet connection
  net_icon="$wired_icon"
else
  # Unknown or disconnected
  net_icon="󰖪"
fi

### Bluetooth State (via bluetoothctl)
bt_icon="󰂲"  # default: service not running

if systemctl is-active --quiet bluetooth.service; then
  bt_powered=$(bluetoothctl show | awk '/Powered:/ {print $2}')
  if [[ "$bt_powered" == "yes" ]]; then
    bt_connected=$(bluetoothctl info 2>/dev/null | grep -q 'Connected: yes' && echo "yes" || echo "no")
    if [[ "$bt_connected" == "yes" ]]; then
      bt_icon="󰂲"  # connected
    else
      bt_icon="󰂯"  # powered but not connected
    fi
  fi
fi

### Output (for Waybar or Polybar)
echo "$net_icon $bt_icon"
