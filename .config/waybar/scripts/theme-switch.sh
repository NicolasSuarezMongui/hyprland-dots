#!/usr/bin/env bash

WAYBAR_DIR="$HOME/.config/waybar"
THEMES_DIR="$WAYBAR_DIR/themes"
STYLE_LINK="$WAYBAR_DIR/style.css"

# Buscar todos los temas disponibles
mapfile -t THEMES < <(find "$THEMES_DIR" -name "*.css" -type f | sort)

if [[ ${#THEMES[@]} -eq 0 ]]; then
  # notify-send "Waybar" "No hay temas disponibles en $THEMES_DIR" -u critical
  echo "No hay temas disponibles"
  exit 1
fi

# Obtener el tema actual
CURRENT=$(readlink -f "$STYLE_LINK" 2>/dev/null)

# Si no hay enlace, usar el primero
if [[ -z "$CURRENT" ]]; then
  NEXT_INDEX=0
else
  # Buscar el índice del tema actual
  NEXT_INDEX=0
  for i in "${!THEMES[@]}"; do
    if [[ "${THEMES[$i]}" == "$CURRENT" ]]; then
      NEXT_INDEX=$(((i + 1) % ${#THEMES[@]}))
      break
    fi
  done
fi

# Crear el enlace simbólico al siguiente tema
NEXT_THEME="${THEMES[$NEXT_INDEX]}"
ln -sf "$NEXT_THEME" "$STYLE_LINK"

# Obtener el nombre del tema para la notificación
THEME_NAME=$(basename "$NEXT_THEME" .css)

# Notificar el cambio
#notify-send "Waybar Theme" "Cambiado a: $THEME_NAME" -t 2000
echo "tema cambiado"

# Recargar Waybar
if pgrep -x waybar >/dev/null; then
  killall -SIGUSR2 waybar 2>/dev/null || {
    killall waybar
    waybar &
    disown
  }
fi
