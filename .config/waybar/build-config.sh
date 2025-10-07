#!/usr/bin/env bash
WAYBAR_DIR="$HOME/.config/waybar"
OUTPUT="$WAYBAR_DIR/config"
TEMP_DIR=$(mktemp -d)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para limpiar JSONC a JSON válido (por el uso de jq)
clean_jsonc() {
  local file="$1"
  # Primero eliminamos comentarios de línea y de bloque
  sed -e 's|^\s*//.*$||g' \
    -e 's|\s*//.*$||g' \
    -e 's|/\*[^*]*\*\+\([^/*][^*]*\*\+\)*/||g' \
    -e 's/,\s*\([\]}]\)/\1/g' "$file" |
    grep -v '^\s*$'
}

# Función de limpieza
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Configuracion de orden de modulos
MODULE_ORDER_LEFT=(
  "custom/menu"
  "custom/theme"
  "hyprland/workspaces"
  "custom/cava"
  "tray"
)

MODULE_ORDER_CENTER=(
  "clock"
)

MODULE_ORDER_RIGHT=(
  "network"
  "pulseaudio"
)

# Array de archivos a procesar
files=(
  "$WAYBAR_DIR/config.jsonc"
  "$WAYBAR_DIR/modules/menu.jsonc"
  "$WAYBAR_DIR/modules/workspaces.jsonc"
  "$WAYBAR_DIR/modules/themes.jsonc"
  "$WAYBAR_DIR/modules/tray.jsonc"
  "$WAYBAR_DIR/modules/center-clock.jsonc"
  "$WAYBAR_DIR/modules/right.jsonc"
)

echo -e "${BLUE}🔨 Construyendo configuración de Waybar...${NC}"

# Limpiar cada archivo JSONC y guardarlo como JSON temporal
temp_files=()
for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    temp_file="$TEMP_DIR/$(basename "$file" .jsonc).json"
    clean_jsonc "$file" >"$temp_file"
    # Verificar que el JSON es válido
    if ! jq empty "$temp_file" 2>/dev/null; then
      echo -e "${RED}❌ ERROR: JSON inválido en $file${NC}" >&2
      echo -e "${YELLOW}Contenido procesado:${NC}"
      cat "$temp_file"
      exit 1
    fi
    temp_files+=("$temp_file")
    echo -e "${GREEN}✓${NC} $(basename "$file")"
  else
    echo -e "${YELLOW}⚠️  Advertencia: $file no existe, se omite${NC}"
  fi
done

# Verificar que hay archivos para procesar
if [[ ${#temp_files[@]} -eq 0 ]]; then
  echo -e "${RED}❌ ERROR: No se encontraron archivos para procesar${NC}" >&2
  exit 1
fi

# Crear el archivo de orden como JSON
cat >"$TEMP_DIR/order.json" <<EOF
{
  "order_left": $(printf '%s\n' "${MODULE_ORDER_LEFT[@]}" | jq -R . | jq -s .),
  "order_center": $(printf '%s\n' "${MODULE_ORDER_CENTER[@]}" | jq -R . | jq -s .),
  "order_right": $(printf '%s\n' "${MODULE_ORDER_RIGHT[@]}" | jq -R . | jq -s .)
}
EOF

# Combinar archivos con jq, respetando el orden definido
if jq -s --slurpfile order "$TEMP_DIR/order.json" '
  # Primero hacemos el merge básico
  reduce .[] as $item (
    {};
    . as $current |
    ($current * $item) |
    .["modules-left"] = (
      ($current["modules-left"] // []) + ($item["modules-left"] // [])
    ) |
    .["modules-center"] = (
      ($current["modules-center"] // []) + ($item["modules-center"] // [])
    ) |
    .["modules-right"] = (
      ($current["modules-right"] // []) + ($item["modules-right"] // [])
    )
  ) |
  # Ahora ordenamos según el array de orden y eliminamos duplicados
  . as $merged |
  .["modules-left"] = (
    [$merged["modules-left"][] | select(. != null)] | unique |
    [($order[0].order_left[] | select(. as $ordered | any($merged["modules-left"][]; . == $ordered))),
     ($merged["modules-left"][] | select(. as $item | all($order[0].order_left[]; . != $item)))]
  ) |
  .["modules-center"] = (
    [$merged["modules-center"][] | select(. != null)] | unique |
    [($order[0].order_center[] | select(. as $ordered | any($merged["modules-center"][]; . == $ordered))),
     ($merged["modules-center"][] | select(. as $item | all($order[0].order_center[]; . != $item)))]
  ) |
  .["modules-right"] = (
    [$merged["modules-right"][] | select(. != null)] | unique |
    [($order[0].order_right[] | select(. as $ordered | any($merged["modules-right"][]; . == $ordered))),
     ($merged["modules-right"][] | select(. as $item | all($order[0].order_right[]; . != $item)))]
  )
' "${temp_files[@]}" >"$OUTPUT"; then
  echo ""
  echo -e "${GREEN}✅ Waybar config rebuilt -> $OUTPUT${NC}"
  echo -e "${BLUE}📦 Módulos incluidos:${NC}"
  echo -e "${YELLOW}  Left:${NC}"
  jq -r '.["modules-left"][]?' "$OUTPUT" | sed 's/^/    • /'
  echo -e "${YELLOW}  Center:${NC}"
  jq -r '.["modules-center"][]?' "$OUTPUT" | sed 's/^/    • /'
  echo -e "${YELLOW}  Right:${NC}"
  jq -r '.["modules-right"][]?' "$OUTPUT" | sed 's/^/    • /'

  # Recargar Waybar si está corriendo
  if pgrep -x waybar >/dev/null; then
    echo ""
    echo -e "${BLUE}🔄 Recargando Waybar...${NC}"
    killall -SIGUSR2 waybar 2>/dev/null || (killall waybar && waybar &)
  fi
else
  echo -e "${RED}❌ ERROR: Falló la reconstrucción de la configuración de Waybar.${NC}" >&2
  exit 1
fi
