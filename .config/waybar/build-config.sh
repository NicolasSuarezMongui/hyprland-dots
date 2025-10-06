#!/usr/bin/env bash

WAYBAR_DIR="$HOME/.config/waybar"
OUTPUT="$WAYBAR_DIR/config"
TEMP_DIR=$(mktemp -d)

# Función para limpiar JSONC a JSON válido
clean_jsonc() {
  local file="$1"
  # Elimina comentarios // y /* */ y comas finales antes de ] o }
  sed -e 's|//.*||g' \
    -e 's|/\*.*\*/||g' \
    -e 's/,\s*\([]}]\)/\1/g' "$file"
}

# Función de limpieza
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Array de archivos a procesar
files=(
  "$WAYBAR_DIR/config.jsonc"
  "$WAYBAR_DIR/modules/menu.jsonc"
  "$WAYBAR_DIR/modules/workspaces.jsonc"
  "$WAYBAR_DIR/modules/center.jsonc"
  "$WAYBAR_DIR/modules/right.jsonc"
)

# Limpiar cada archivo JSONC y guardarlo como JSON temporal
temp_files=()
for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    temp_file="$TEMP_DIR/$(basename "$file" .jsonc).json"
    clean_jsonc "$file" >"$temp_file"
    temp_files+=("$temp_file")
  else
    echo "⚠️  Advertencia: $file no existe, se omite"
  fi
done

# Verificar que hay archivos para procesar
if [[ ${#temp_files[@]} -eq 0 ]]; then
  echo "❌ ERROR: No se encontraron archivos para procesar" >&2
  exit 1
fi

# Combinar archivos con jq, concatenando arrays y mergeando objetos
if jq -s '
  reduce .[] as $item (
    {};
    # Guardamos estado actual antes del merge
    . as $current |
    # Hacemos merge de todos los campos excepto los arrays de módulos
    ($current * $item) |
    # Ahora concatenamos los arrays explícitamente
    .["modules-left"] = (
      ($current["modules-left"] // []) + ($item["modules-left"] // []) | unique
    ) |
    .["modules-center"] = (
      ($current["modules-center"] // []) + ($item["modules-center"] // []) | unique
    ) |
    .["modules-right"] = (
      ($current["modules-right"] // []) + ($item["modules-right"] // []) | unique
    )
  )
' "${temp_files[@]}" >"$OUTPUT"; then
  echo "✅ Waybar config rebuilt -> $OUTPUT"
  echo "📦 Módulos incluidos:"
  jq -r '.["modules-left"][]?, .["modules-center"][]?, .["modules-right"][]?' "$OUTPUT" | sed 's/^/   - /'
else
  echo "❌ ERROR: Falló la reconstrucción de la configuración de Waybar." >&2
  exit 1
fi
