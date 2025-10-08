#!/usr/bin/env bash

STATE_FILE="/tmp/waybar-mem-state"

# Toggle mode
if [[ "$1" == "toggle" ]]; then
  if [[ -f "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
  else
    touch "$STATE_FILE"
  fi
  exit 0
fi

MODE="text"
[[ -f "$STATE_FILE" ]] && MODE="bar"

# Obtener información de memoria
read -r TOTAL USED AVAILABLE <<<"$(free -m | awk '/^Mem:/ {print $2, $3, $7}')"
PERCENTAGE=$((USED * 100 / TOTAL))

# Convertir a GB si es necesario
if ((TOTAL > 1024)); then
  TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $TOTAL/1024}")
  USED_GB=$(awk "BEGIN {printf \"%.1f\", $USED/1024}")
  AVAIL_GB=$(awk "BEGIN {printf \"%.1f\", $AVAILABLE/1024}")
  DISPLAY_USED="${USED_GB}G"
  DISPLAY_TOTAL="${TOTAL_GB}G"
else
  DISPLAY_USED="${USED}M"
  DISPLAY_TOTAL="${TOTAL}M"
fi

read -r SWAP_TOTAL SWAP_USED <<<"$(free -m | awk '/^Swap:/ {print $2, $3}')"
SWAP_PERCENTAGE=0
[[ $SWAP_TOTAL -gt 0 ]] && SWAP_PERCENTAGE=$((SWAP_USED * 100 / SWAP_TOTAL))

TOP_PROCS=$(ps aux --sort=-%mem | awk 'NR>1 {printf "%s: %.1f%%\n", $11, $4}' | head -3)

if ((PERCENTAGE >= 90)); then
  CLASS="critical"
elif ((PERCENTAGE >= 80)); then
  CLASS="warning"
elif ((PERCENTAGE >= 70)); then
  CLASS="high"
else
  CLASS="normal"
fi

if [[ "$MODE" == "bar" ]]; then
  # Crear barra de progreso
  BAR_LENGTH=10
  FILLED=$((PERCENTAGE * BAR_LENGTH / 100))
  EMPTY=$((BAR_LENGTH - FILLED))

  BAR=""
  for ((i = 0; i < FILLED; i++)); do BAR+="█"; done
  for ((i = 0; i < EMPTY; i++)); do BAR+="░"; done

  TEXT=" $BAR ${PERCENTAGE}%"
else
  TEXT=" ${DISPLAY_USED}/${DISPLAY_TOTAL}"
fi

TOOLTIP="Memoria: ${PERCENTAGE}%\nUsada: ${DISPLAY_USED} / ${DISPLAY_TOTAL}\nDisponible: ${AVAIL_GB:-${AVAILABLE}M}G"

if [[ $SWAP_TOTAL -gt 0 ]]; then
  SWAP_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $SWAP_TOTAL/1024}")
  SWAP_USED_GB=$(awk "BEGIN {printf \"%.1f\", $SWAP_USED/1024}")
  TOOLTIP="$TOOLTIP\n\nSwap: ${SWAP_PERCENTAGE}%\nUsada: ${SWAP_USED_GB}G / ${SWAP_TOTAL_GB}G"
fi

TOOLTIP="$TOOLTIP\n\nTop procesos:\n$TOP_PROCS"

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}" | tr '\n' ' '
