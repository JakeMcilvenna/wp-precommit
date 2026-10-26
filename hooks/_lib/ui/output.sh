#!/bin/bash
source "$UI_DIR/colors.sh"

success() {
  echo "${GREEN}[ ✔ ] $*${RESET}"
}

error() {
  echo "${RED}[ ✘ ] $*${RESET}"
}

warn() {
  echo "${YELLOW}[ ! ] $*${RESET}"
}

info() {
  echo "${BLUE}[ i ] $*${RESET}"
}

skip() {
  echo "${MAGENTA}[ ⏭ ] $*${RESET}"
}

debug() {
  if [ "${DEBUG:-false}" = true ]; then
    echo "" >&2 
    echo "${CYAN}[ 🔎 ] $*${RESET}" >&2
    echo "" >&2 
  fi
}

debug_block() {
  if [ "${DEBUG:-false}" = true ]; then
    local header="$1"
    local content="$(echo "$2" | sed '/^$/d')" 

    echo "${CYAN}[ 🔎 ] $header${RESET}" >&2
    if [ -n "$content" ]; then
      echo "$content" >&2
    fi
    echo "" >&2
  fi
}


hr() {
  echo "──────────────────────────────"
}

newline() { echo ""; }