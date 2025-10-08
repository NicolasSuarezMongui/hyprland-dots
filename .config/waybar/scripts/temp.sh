#!/usr/bin/env bash

# Intentar obtener temperatura de diferentes fuentes
get_temperature() {
  local temp=""

  # Método 1: sensors (lm-sensors)
  if command -v sensors &>/dev/null; then
    temp=$(sensors 2>/dev/null | awk '/^Package id 0:/ {print $4}' | tr -d '+°C')
    [[ -n "$temp" ]] && echo "$temp" && return 0

    # Fallback: Tdie o Tctl (AMD)
    temp=$(sensors 2>/dev/null | awk '/^Tdie:/ {print $2}' | tr -d '+°C')
    [[ -n "$temp" ]] && echo "$temp" && return 0

    temp=$(sensors 2>/dev/null | awk '/^Tctl:/ {print $2}' | tr -d '+°C')
    [[ -n "$temp" ]] && echo "$temp" && return 0

    # Fallback: Core 0 (general)
    temp=$(sensors 2>/dev/null | awk '/^Core 0:/ {print $3}' | tr -d '+°C')
    [[ -n "$temp" ]] && echo "$temp" && return 0
  fi

  # Método 2: /sys/class/thermal
  if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    temp=$((temp / 1000))
    echo "$temp"
    return 0
  fi

  # Método 3: hwmon
  for hwmon in /sys/class/hwmon/hwmon*/temp1_input; do
    if [[ -f "$hwmon" ]]; then
      temp=$(cat "$hwmon")
      temp=$((temp / 1000))
      echo "$temp"
      return 0
    fi
  done

  return 1
}

# Obtener temperatura
TEMP=$(get_temperature)

if [[ -z "$TEMP" ]]; then
  echo '{"text": "  N/A", "tooltip": "No se pudo leer la temperatura\nInstala: lm-sensors", "class": "error"}'
  exit 0
fi

# Redondear a entero
TEMP=${TEMP%.*}

# Determinar icono y clase según temperatura
if ((TEMP >= 80)); then
  ICON=""
  CLASS="critical"
  TOOLTIP="⚠️ Temperatura CRÍTICA: ${TEMP}°C"
elif ((TEMP >= 70)); then
  ICON=""
  CLASS="warning"
  TOOLTIP="⚠️ Temperatura alta: ${TEMP}°C"
elif ((TEMP >= 60)); then
  ICON=""
  CLASS="high"
  TOOLTIP="Temperatura: ${TEMP}°C"
else
  ICON=""
  CLASS="normal"
  TOOLTIP="Temperatura: ${TEMP}°C"
fi

echo "{\"text\": \"$ICON ${TEMP}°C\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
