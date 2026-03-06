#!/usr/bin/env bash

# ─── Icons ─────────────────────────────────────────────────────────────────────
cpu_icon=""
mem_icon=""
gpu_icon="󰘚"
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

# ─── GPU USAGE (NVIDIA) ───────────────────────────────────────────────────────
gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

# ─── OUTPUT FOR WAYBAR ───────────────────────────────────────────────────────
echo "$cpu_icon ${cpu}%  $mem_icon ${mem}% $gpu_icon ${gpu}% $temp_icon ${temp}°C"
