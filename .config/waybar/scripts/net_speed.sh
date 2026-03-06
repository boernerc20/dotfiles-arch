#!/usr/bin/env bash

# Pick your interface (auto-detect the first non-loopback with carrier)
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)

# Nerd Font icons
ICON_DOWN=""  # nf-mdi-download
ICON_UP=""    # nf-mdi-upload

# Track previous rx/tx bytes
RX_PREV=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_PREV=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

while true; do
    sleep 1

    RX_NOW=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX_NOW=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

    RX_DIFF=$((RX_NOW - RX_PREV))
    TX_DIFF=$((TX_NOW - TX_PREV))

    RX_PREV=$RX_NOW
    TX_PREV=$TX_NOW

    # Convert to human-readable KB/s or MB/s
    format_speed() {
        local SPEED=$1
        if [ $SPEED -lt 1024 ]; then
            echo "${SPEED}B/s"
        elif [ $SPEED -lt 1048576 ]; then
            echo "$((SPEED / 1024))K"
        else
            echo "$((SPEED / 1048576))M"
        fi
    }

    RX_HUMAN=$(format_speed $RX_DIFF)
    TX_HUMAN=$(format_speed $TX_DIFF)

    echo "$ICON_DOWN $RX_HUMAN $ICON_UP $TX_HUMAN"
  done

