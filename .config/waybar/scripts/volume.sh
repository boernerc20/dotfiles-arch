#!/usr/bin/env bash
# volume.sh — PipeWire / PulseAudio volume widget with changing icon

# get volume (0–100) and mute state
vol=$(pactl get-sink-volume @DEFAULT_SINK@ \
      | awk '/Volume/ {print $5}' | tr -d '%')
muted=$(pactl get-sink-mute  @DEFAULT_SINK@ \
      | awk '{print $2}')

if [[ $muted == "yes" ]]; then
  icon=""   # muted speaker
else
  # choose icon based on volume thresholds
  if   (( vol == 0 ));       then icon=" "
  elif (( vol <= 30 ));      then icon=" "  # low
  elif (( vol <= 70 ));      then icon=" "  # medium
  else                        icon="? "  # high
  fi
fi

echo "$icon ${vol}%"
