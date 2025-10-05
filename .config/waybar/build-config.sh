#!/usr/bin/env bash

WAYBAR_DIR="$HOME/.config/waybar"
OUTPUT="$WAYBAR_DIR/config"

if jq -s 'reduce .[] as $item ({}; . * $item)' \
  "$WAYBAR_DIR/config.jsonc" \
  "$WAYBAR_DIR/modules/left.jsonc" \
  "$WAYBAR_DIR/modules/center.jsonc" \
  "$WAYBAR_DIR/modules/right.jsonc" \
  >"$OUTPUT"; then
  echo "✅ Waybar config rebuilt -> $OUTPUT"
else
  echo "❌ ERROR: Falló la reconstrucción de la configuración de Waybar." >&2
  exit 1
fi
