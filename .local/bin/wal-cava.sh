#!/usr/bin/env bash
# wal-cava.sh — regenerate CAVA colors and signal CAVA to reload

# 1) Copy the generated CAVA config into place
cp ~/.cache/wal/config.cava ~/.config/cava/config

# 2) Tell any running CAVA to reload its config
pidof cava &>/dev/null && kill -USR2 "$(pidof cava)"
