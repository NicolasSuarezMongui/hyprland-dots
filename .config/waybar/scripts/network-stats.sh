#!/usr/bin/env bash

IFACE=$(ip route | awk '/default/ {print $5}')
RX1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
sleep 1
RX2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

RX_RATE=$(((RX2 - RX1) / 1024))
TX_RATE=$(((TX2 - TX1) / 1024))

SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2- | head -n 1)

if [ -z "$SSID" ]; then
  TEXT="󰤯 "
  TOOLTIP="Desconectado"
else
  TEST=" $SSID"
  TOOLTIP="↓ ${RX_RATE}KB/s ↑ ${TX_RATE}KB/s"
fi

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\"}"
