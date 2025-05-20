#!/usr/bin/env bash

WALLPAPER="$1"

# choose Rofi mode by wallpaper filename
case "$(basename "$WALLPAPER")" in
  blade_runner.png) MODE="c1"  ;;  # “APPS” launcher
  mclaren.png)      MODE="c2"  ;;  # “RUN” prompt
  jig_jig.png)      MODE="c3"  ;;  # “FILES” browser
  gate.png)         MODE="c4"  ;;  # “WINDOW” switcher
  cyber_car.png)    MODE="c5"  ;;
  *)                MODE="drun";;  # fallback to APPS
esac

# pick the right Rofi theme
cp ~/.cache/wal/colors-rofi-"$MODE".rasi \
   ~/.config/rofi/colors-rofi.rasi

