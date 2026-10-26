#!/bin/bash
source "$UI_DIR/colors.sh"
source "$UI_DIR/output.sh"

banner() {
  newline
  echo "${BOLD}${BLUE}HUSKYPRE-COMMIT${RESET}"
  echo "${BLUE}──────────────────────────────${RESET}"
  echo "${BLUE}Running JS, CSS/SCSS, and PHP checks...${RESET}"
  echo "${BLUE}Auto-fix where possible, block if not.${RESET}"
  echo "${BLUE}──────────────────────────────${RESET}"
}