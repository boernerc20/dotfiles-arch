#!/usr/bin/env bash
# volume.sh — PipeWire / PulseAudio volume widget with changing icon
#
# NOT WIRED INTO THE BAR. config.jsonc uses waybar's built-in "pulseaudio"
# module instead; this is kept as a standalone/fallback readout. Its icons are
# deliberately the SAME nf-md codepoints that module is configured with, so if
# it is ever swapped back in, the bar looks identical.
#
# The icons used to be Font Awesome (U+F026/F027/F028), which sit in the BMP
# Private Use Area and get silently destroyed on some writes. U+F028 had already
# degraded to a literal ASCII "?" here, so the high-volume state rendered as
# "? 100%". verify-glyphs.py did not catch it: "?" is a real glyph present in
# the font, so a coverage check passes. nf-md (U+F0000+) is not affected.

# get volume (0-100) and mute state
vol=$(pactl get-sink-volume @DEFAULT_SINK@ \
      | awk '/Volume/ {print $5}' | tr -d '%')
muted=$(pactl get-sink-mute  @DEFAULT_SINK@ \
      | awk '{print $2}')

if [[ $muted == "yes" ]]; then
  icon="󰝟"   # nf-md-volume_off
else
  # choose icon based on volume thresholds
  if   (( vol == 0 ));       then icon="󰝟"   # nf-md-volume_off
  elif (( vol <= 30 ));      then icon="󰕿"   # nf-md-volume_low
  elif (( vol <= 70 ));      then icon="󰖀"   # nf-md-volume_medium
  else                            icon="󰕾"  # nf-md-volume_high
  fi
fi

echo "$icon ${vol}%"
