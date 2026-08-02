#!/usr/bin/env bash

# Icon-to-value gap. A literal space is a full monospace cell, the same
# width as the gap between words, so the icon floated instead of binding to
# its value. Pango letter_spacing is ignored in these labels (GTK's CSS
# letter-spacing wins), but a space scaled with `size` does take effect.
# Keep this identical across every bar script — it is a consistency rule.
GAP="<span size='8704'> </span>"

# Weather with local °F 

source "${HOME}/.config/waybar/weather.env"
API_KEY="${OPENWEATHER_API_KEY}"
CITY="Falls Church, US"

###############################################################################
# fetch once in °F
###############################################################################
weather=$(curl -sf \
  -G "https://api.openweathermap.org/data/2.5/weather" \
  --data-urlencode "q=$CITY" \
  --data-urlencode "appid=$API_KEY" \
  --data-urlencode "units=imperial"
) || { echo "󰀦${GAP}Weather"; exit 1; }

temp_f=$(jq '.main.temp' <<<"$weather")
desc=$(jq -r '.weather[0].main' <<<"$weather")

###############################################################################
# icon
###############################################################################
case $desc in
  Clear)                icon="" ;;
  Clouds)               icon="" ;;
  Rain)                 icon="" ;;
  Drizzle)              icon="" ;;
  Thunderstorm)         icon="" ;;
  Snow)                 icon="" ;;
  Mist|Fog|Haze)        icon="" ;;
  *)                    icon="" ;;
esac

temp=$(awk "BEGIN{printf \"%.0f\", $temp_f}")
symbol="°F"

echo "${icon}${GAP}${temp}${symbol}"
