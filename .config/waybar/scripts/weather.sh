#!/usr/bin/env bash

# Weather with local °F 

# Get a free API key at https://openweathermap.org/api
API_KEY="${OPENWEATHER_API_KEY:-your-api-key-here}"
# Set your city, e.g. "London, UK" or "New York, US"
CITY="${OPENWEATHER_CITY:-your-city-here}"

###############################################################################
# fetch once in °F
###############################################################################
weather=$(curl -sf \
  -G "https://api.openweathermap.org/data/2.5/weather" \
  --data-urlencode "q=$CITY" \
  --data-urlencode "appid=$API_KEY" \
  --data-urlencode "units=imperial"
) || { echo " Weather"; exit 1; }

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

echo "$icon ${temp}${symbol}"
