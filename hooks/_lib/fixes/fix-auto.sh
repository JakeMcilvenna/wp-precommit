#!/bin/bash
source "$CORE_DIR/config.sh"

set_spinner "spinner1"

info "🔧 Attempting automatic fixes..."
newline

EXIT_CODE=0

PRETTIER_FAILED=0
STYLELINT_FAILED=0
ESLINT_FAILED=0
PHPCS_FAILED=0

# Clear previous failure records
rm -f "$TMP_DIR/failed_"*

# --------------------------------------------------
# Prettier
# --------------------------------------------------
if [ -n "$STAGED_JS" ] || [ -n "$STAGED_CSS" ]; then
  FIX_CMD=(npx prettier --write $STAGED_JS $STAGED_CSS)
  CHECK_CMD=(npx prettier --check $STAGED_JS $STAGED_CSS)
  run_fix_and_check_step "Prettier" FIX_CMD[@] CHECK_CMD[@] "PRETTIER_FAILED" || EXIT_CODE=1

  if [ "${PRETTIER_FAILED:-0}" -eq 1 ]; then
    > "$TMP_DIR/failed_prettier"
    for f in $STAGED_JS $STAGED_CSS; do
      npx prettier --check "$f" >/dev/null 2>&1 || echo "$f" >> "$TMP_DIR/failed_prettier"
    done
  fi
  newline
else
  skip "Skipping Prettier – no JS/CSS files involved."
  newline
fi

# --------------------------------------------------
# Stylelint
# --------------------------------------------------
if [ -n "$STAGED_CSS" ]; then
  FIX_CMD=(npx stylelint --fix $STAGED_CSS)
  CHECK_CMD=(npx stylelint --color $STAGED_CSS)
  run_fix_and_check_step "Stylelint" FIX_CMD[@] CHECK_CMD[@] "STYLELINT_FAILED" || EXIT_CODE=1

  if [ "${STYLELINT_FAILED:-0}" -eq 1 ]; then
    > "$TMP_DIR/failed_stylelint"
    for f in $STAGED_CSS; do
      npx stylelint "$f" >/dev/null 2>&1 || echo "$f" >> "$TMP_DIR/failed_stylelint"
    done
  fi
  newline
else
  skip "Skipping Stylelint – no CSS/SCSS files involved."
  newline
fi

# --------------------------------------------------
# ESLint
# --------------------------------------------------
if [ -n "$STAGED_JS" ]; then
  FIX_CMD=(npx eslint --fix $STAGED_JS)
  CHECK_CMD=(npx eslint --color $STAGED_JS)
  run_fix_and_check_step "ESLint" FIX_CMD[@] CHECK_CMD[@] "ESLINT_FAILED" || EXIT_CODE=1

  if [ "${ESLINT_FAILED:-0}" -eq 1 ]; then
    > "$TMP_DIR/failed_eslint"
    for f in $STAGED_JS; do
      npx eslint "$f" >/dev/null 2>&1 || echo "$f" >> "$TMP_DIR/failed_eslint"
    done
  fi
  newline
else
  skip "Skipping ESLint – no JS files involved."
  newline
fi

# --------------------------------------------------
# PHPCS / PHPCBF
# --------------------------------------------------
if [ -n "$STAGED_PHP" ]; then
  FIX_CMD=(vendor/bin/phpcbf $STAGED_PHP)
  CHECK_CMD=(vendor/bin/phpcs $STAGED_PHP)
  run_php_fix_and_check_step FIX_CMD[@] CHECK_CMD[@] "PHPCS_FAILED" || EXIT_CODE=1

  if [ "${PHPCS_FAILED:-0}" -eq 1 ]; then
    > "$TMP_DIR/failed_phpcs"
    for f in $STAGED_PHP; do
      vendor/bin/phpcs "$f" >/dev/null 2>&1 || echo "$f" >> "$TMP_DIR/failed_phpcs"
    done
  fi
  newline
else
  skip "Skipping PHPCBF – no PHP files involved."
  newline
fi

# Normalize vars (in case unset)
PRETTIER_FAILED=${PRETTIER_FAILED:-0}
STYLELINT_FAILED=${STYLELINT_FAILED:-0}
ESLINT_FAILED=${ESLINT_FAILED:-0}
PHPCS_FAILED=${PHPCS_FAILED:-0}

# --------------------------------------------------
# Summary
# --------------------------------------------------
source "$UI_DIR/summary.sh"

# --------------------------------------------------
# Final message & decision
# --------------------------------------------------
if [ "$EXIT_CODE" -eq 0 ]; then
  newline
  success "All fixable issues resolved and staged. Proceeding with commit..."
  echo "$STAGED_FILES" | xargs git add
  exit 0
else
  newline
  warn "Some issues could not be fixed automatically."
  newline
  echo "${BOLD}What would you like to do?${RESET}"
  hr
  echo "[1] Enter guided fix mode (interactive)"
  echo "[2] Abort commit"
  hr
  read -r choice < /dev/tty
  newline

  if [ "$choice" = "1" ]; then
    export AUTO_FIX_ATTEMPTED=1
    source "$FIXES_DIR/fix-guided.sh"
  else
    error "Commit aborted due to unresolved issues."
    exit 1
  fi
fi

# --------------------------------------------------
# Pass only failed files to the recheck
# --------------------------------------------------
STAGED_JS=$(cat "$TMP_DIR/failed_eslint" 2>/dev/null || echo "")
STAGED_CSS=$(cat "$TMP_DIR/failed_stylelint" 2>/dev/null || echo "")
STAGED_PHP=$(cat "$TMP_DIR/failed_phpcs" 2>/dev/null || echo "")
export STAGED_JS STAGED_CSS STAGED_PHP