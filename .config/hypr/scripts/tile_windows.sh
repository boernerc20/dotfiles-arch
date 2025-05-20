#!/bin/bash

# Tile all floating windows
hyprctl clients -j | jq -r '.[] | select(.floating == true) | .address' | while read -r addr; do
    hyprctl dispatch togglefloating address:$addr
done
