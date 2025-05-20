#!/bin/bash

# Float and center all currently open windows
hyprctl clients -j | jq -r '.[].address' | while read -r addr; do
    hyprctl dispatch togglefloating address:$addr
    hyprctl dispatch centerwindow address:$addr
done
