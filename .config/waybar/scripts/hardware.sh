#!/usr/bin/env bash

# ─── Icons ─────────────────────────────────────────────────────────────────────
cpu_icon=""
mem_icon=""
gpu_icon="󰘚"
bat_empty_icon="󰂎"
bat_full_icon="󰁹"
bat_charging_icon="󰂄"
temp_icon=""

# ─── CPU USAGE ─────────────────────────────────────────────────────────────────
# Read first snapshot
read -r -a cpu_fields < /proc/stat
idle1=${cpu_fields[4]}
total1=0
for value in "${cpu_fields[@]:1}"; do
  total1=$(( total1 + value ))
done

sleep 0.5

# Read second snapshot
read -r -a cpu_fields < /proc/stat
idle2=${cpu_fields[4]}
total2=0
for value in "${cpu_fields[@]:1}"; do
  total2=$(( total2 + value ))
done

# Compute usage
diff_idle=$(( idle2 - idle1 ))
diff_total=$(( total2 - total1 ))
if (( diff_total > 0 )); then
  cpu=$(( (diff_total - diff_idle) * 100 / diff_total ))
else
  cpu=0
fi

# ─── MEMORY USAGE ───────────────────────────────────────────────────────────────
mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
if (( mem_total > 0 )); then
  mem=$(( (mem_total - mem_avail) * 100 / mem_total ))
else
  mem=0
fi

# ─── CPU TEMPERATURE ──────────────────────────────────────────────────────────
# Works for both Intel (x86_pkg_temp) and AMD (k10temp)
temp=$(
  for hwmon in /sys/class/hwmon/hwmon*; do
    name=$(cat "$hwmon/name" 2>/dev/null)
    if [[ "$name" == "k10temp" || "$name" == "coretemp" ]]; then
      temp_input=$(cat "$hwmon/temp1_input" 2>/dev/null)
      if [[ -n "$temp_input" ]]; then
        echo $((temp_input / 1000))
        break
      fi
    fi
  done
)

# ─── FOURTH FIELD: NVIDIA GPU POWER DRAW, OR BATTERY IF NO GPU ────────────────
# Auto-detected rather than forked per machine. This desktop has an NVIDIA GPU
# and no battery; the laptop has a battery and no discrete GPU. One script
# handles both by checking what the hardware actually offers, so a fresh clone
# on either machine needs no local edit — and no local diff to keep in sync.
fourth_icon=""
fourth_value=""
fourth_unit=""

if command -v nvidia-smi &>/dev/null && nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits &>/dev/null; then
  gpu_power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits | awk '{printf "%d", $1}')
  fourth_icon="$gpu_icon"
  fourth_value="$gpu_power"
  fourth_unit="W"
elif [[ -r /sys/class/power_supply/BAT0/capacity ]]; then
  bat_capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
  bat_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
  fourth_icon="$bat_full_icon"
  [[ "$bat_status" == "Charging" ]] && fourth_icon="$bat_charging_icon"
  (( bat_capacity < 20 )) && [[ "$bat_status" != "Charging" ]] && fourth_icon="$bat_empty_icon"
  fourth_value="$bat_capacity"
  fourth_unit="%"
fi

# ─── OUTPUT FOR WAYBAR ───────────────────────────────────────────────────────
# Icon-to-value gap. A literal space is a full monospace cell, the same
# width as the gap between words, so the icon floated instead of binding to
# its value. Pango letter_spacing is ignored in these labels (GTK's CSS
# letter-spacing wins), but a space scaled with `size` does take effect.
# Keep this identical across every bar script — it is a consistency rule.
GAP="<span size='8704'> </span>"

# Field separator: a dim divider, matching the clock and mpris pills, which use
# the same U+2502 (Box Drawing — deliberately NOT a Private Use Area glyph, see
# the warning in config.jsonc). This replaced two plain spaces, which read as an
# accidental gap and made the four readings look like four separate modules
# crammed into one pill rather than one instrument.
SEP="<span alpha='30%'>│</span>"

# NO PADDING. An earlier version padded every value to its maximum digit count
# so the pill could never resize. It worked — verified at a constant 318px — but
# it made this pill far wider and more spaced-out than every other module on the
# bar, which is a worse problem than the resize it fixed.
#
# The reference modules (pulseaudio, disk, weather) are all plainly
# `icon + GAP + value` with no padding, and they simply accept the width change
# as their numbers cross 9->10->100. This module now does the same. If the
# jitter ever becomes intolerable, the fix is FEWER FIELDS, not padding: note
# that CSS cannot help, since GTK implements min-width but not max-width.
[[ "$fourth_value" =~ ^[0-9]+$ ]] || fourth_value=0
[[ "$temp" =~ ^[0-9]+$ ]] || temp=0

# Built by concatenation rather than one big printf format. The format-string
# version was miscounted once already: "%s%s%s%%%s..." mixes literal %% in among
# the conversions, printf ran out of arguments, and it silently RECYCLED the
# format — emitting a stray "%%W°C" tail. Concatenation cannot drift this way.
field() {   # icon, value, unit
    printf '%s%s%s%s' "$1" "$GAP" "$2" "$3"
}

# Fourth field only prints if the hardware check above actually found something
# — a machine with neither a GPU nor a battery (unlikely, but cheap to handle)
# falls back to CPU/MEM/TEMP with no dangling separator.
if [[ -n "$fourth_icon" ]]; then
  printf '%s %s %s %s %s %s %s\n' \
    "$(field "$cpu_icon"    "$cpu"          '%')"  "$SEP" \
    "$(field "$mem_icon"    "$mem"          '%')"  "$SEP" \
    "$(field "$fourth_icon" "$fourth_value" "$fourth_unit")"  "$SEP" \
    "$(field "$temp_icon"   "$temp"         '°C')"
else
  printf '%s %s %s %s %s\n' \
    "$(field "$cpu_icon"  "$cpu"  '%')"  "$SEP" \
    "$(field "$mem_icon"  "$mem"  '%')"  "$SEP" \
    "$(field "$temp_icon" "$temp" '°C')"
fi
