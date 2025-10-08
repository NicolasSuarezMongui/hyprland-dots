#!/usr/bin/env bash

STATE_FILE="/tmp/waybar-cpu-state"

# Toggle mode
if [[ "$1" == "toogle" ]]; then
  if [[ -f "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
  else
    touch "$STATE_FILE"
  fi
  exit 0
fi

MODE="text"
[[ -f "$STATE_FILE" ]] && MODE="bar"

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
CPU_USAGE=${CPU_USAGE%.*}

CPU_CORES=$(nproc)
CPU_FREQ=$(grep "MHz" /proc/cpuinfo | awk '{sum+=$4; count++} END {printf "%.1f", sum/count/1000}')

TOP_PROCS=$(ps aux --sort=-%cpu | awk 'NR>1 {printf "%s: %.1f%%\n", $11, $3}' | head -3)

if ((CPU_USAGE >= 90)); then
  CLASS="critical"
elif ((CPU_USAGE >= 70)); then
  CLASS="warning"
elif ((CPU_USAGE >= 50)); then
  CLASS="high"
else
  CLASS="normal"
fi

if [[ "$MODE" == "bar" ]]; then
  # Crear barra de progreso
  BAR_LENGTH=10
  FILLED=$((CPU_USAGE * BAR_LENGTH / 100))
  EMPTY=$((BAR_LENGTH - FILLED))

  BAR=""
  for ((i = 0; i < FILLED; i++)); do BAR+="█"; done
  for ((i = 0; i < EMPTY; i++)); do BAR+="░"; done

  TEXT=" $BAR ${CPU_USAGE}%"
else
  TEXT=" ${CPU_USAGE}%"
fi

TOOLTIP="CPU: ${CPU_USAGE}%\nCores: $CPU_CORES\nFreq: ${CPU_FREQ} Ghz\n\nTop Procesos:\n$TOP_PROCS"

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}" | tr '\n' ' '
