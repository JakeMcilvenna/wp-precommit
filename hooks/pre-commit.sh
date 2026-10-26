#!/bin/bash

source "$(dirname "$0")/_lib/core/config.sh"

# Banner
source "$UI_DIR/banner.sh"
banner

# Run tool and file checks
source "$CORE_DIR/check-tools.sh"
success "check-tools.sh complete."
newline

# Get staged files
source "$CORE_DIR/get-staged.sh"
success "get-staged.sh complete."
newline

# Bail out early if nothing to check (deletions etc.)
if [ -z "$STAGED_FILES" ]; then
  success "Nothing to check. Proceeding with commit."
  cleanup_caches
  exit 0
fi

# Initial run of checks
source "$CORE_DIR/run-checks.sh"
success "run-checks.sh complete."
newline

# Proceed if nothing failed initially
if [ "$ALL_CLEAN" = "true" ]; then
  success "All staged files passed. Proceeding with commit."
  cleanup_caches
  exit 0
fi

# Loop until a valid fix option is chosen
while true; do
  warn "Issues found. Choose a fix option:"
  hr
  echo "[1] Attempt to fix everything automatically"
  echo "[2] Fix files one-by-one (guided mode)"
  echo "[3] Skip all fixes and proceed with commit"
  echo "[4] Abort commit"
  hr
  read -r choice < /dev/tty
  newline

  case "$choice" in
    1)
      source "$FIXES_DIR/fix-auto.sh"
      break
      ;;
    2)
      source "$FIXES_DIR/fix-guided.sh"
      break
      ;;
    3)
      skip "Skipping all fixes..."
      cleanup_caches
      exit 0
      ;;
    4)
      error "Commit aborted."
      exit 1
      ;;
    *)
      warn "Invalid option. Please choose 1, 2, 3, or 4."
      ;;
  esac
done

# Re-run checks (only if fixes were attempted)
newline
info "Re-checking files after fixes..."
source "$CORE_DIR/run-checks.sh"

if [ "$ALL_CLEAN" = "true" ]; then
  success "All issues resolved after fix. Proceeding with commit."
  cleanup_caches
  exit 0
else
  newline
  error "Some issues remain. Commit blocked."
  exit 1
fi
