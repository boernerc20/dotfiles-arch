#!/usr/bin/env bash

# ─── Icons ─────────────────────────────────────────────────────────────────────
cpu_icon=""
mem_icon=""
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
if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
  rawtemp=$(< /sys/class/thermal/thermal_zone0/temp)
  temp=$(( rawtemp / 1000 ))
else
  temp="N/A"
fi

# ─── OUTPUT FOR WAYBAR ─────────────────────────────────────────────────────────
echo "$cpu_icon ${cpu}%  $mem_icon ${mem}%  $temp_icon ${temp}°C"
