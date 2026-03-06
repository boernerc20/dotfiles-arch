#!/usr/bin/env bash

WALLPAPER="$1"

# choose Rofi mode by wallpaper filename
case "$(basename "$WALLPAPER")" in
  blade_runner.png) MODE="c1"  ;;
  mclaren.png)      MODE="c2"  ;;
  jig_jig.png)      MODE="c3"  ;; 
  gate.png)         MODE="c4"  ;;  
  cyber_car.png)    MODE="c5"  ;;
  japan.png)        MODE="c6"  ;;
  neon-gun.png)     MODE="c7"  ;;
  alpine.png)       MODE="c8"  ;;
  *)                MODE="drun";;  # fallback to APPS
esac

# pick the right Rofi theme
cp ~/.cache/wal/colors-rofi-"$MODE".rasi \
   ~/.config/rofi/colors-rofi.rasi

