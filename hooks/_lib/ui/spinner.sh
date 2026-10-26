#!/bin/bash -e
# Spinner utility – UI only

source "$CORE_DIR/paths.sh"

declare -x FRAME
declare -x FRAME_INTERVAL

# -----------------------------
# Spinner setup
# -----------------------------
set_spinner() {
  case $1 in
    spinner1) FRAME=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"); FRAME_INTERVAL=0.1 ;;
    spinner2) FRAME=("-" "\\" "|" "/"); FRAME_INTERVAL=0.25 ;;
    *) echo "No spinner is defined for $1"; exit 1 ;;
  esac
}

# -----------------------------
# Helpers
# -----------------------------
sanitize_label() {
  echo "$1" | tr -c 'a-zA-Z0-9_' '_'
}

make_cache_file() {
  local label="$1" suffix="${2:-cache}"
  local safe_label
  safe_label=$(sanitize_label "$label")
  local path="$TMP_DIR/.step_${safe_label}.${suffix}"
  mkdir -p "$(dirname "$path")"
  echo "$path"
}

spin_loop() {
  local pid=$1 label=$2 prefix=$3
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    echo -ne "\r\033[K[ ${FRAME[i]} ] $prefix$label..."
    sleep "$FRAME_INTERVAL"
    i=$(( (i + 1) % ${#FRAME[@]} ))
  done
}

finish_spinner() {
  tput cnorm
  echo -ne "\r\033[K"
}
