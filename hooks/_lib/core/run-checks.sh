#!/bin/bash
source "$CORE_DIR/config.sh"

set_spinner "spinner1"

info "run-checks.sh: running..."
newline

ALL_CLEAN=true

# Clean up old failed lists
rm -f "$TMP_DIR/failed_"*

# run from theme dir
cd "$THEME_DIR" || exit 1

mark_failed() {
  local tool="$1"
  export "${tool^^}_FAILED"=1
  ALL_CLEAN=false
}

debug "=== enter run-checks.sh ==="

# -------------------------------------
# Prettier
# -------------------------------------
if [ -n "$STAGED_JS" ] || [ -n "$STAGED_CSS" ]; then
  debug_block "Prettier input files" "$STAGED_JS
$STAGED_CSS"

  if ! run_step "Prettier" npx prettier --check $STAGED_JS $STAGED_CSS; then
    mark_failed "prettier"
    > "$TMP_DIR/failed_prettier"
    for f in $STAGED_JS $STAGED_CSS; do
      npx prettier --check "$f" >/dev/null 2>&1 || echo "$f" >> "$TMP_DIR/failed_prettier"
    done
  fi
  newline
else
  skip "Skipping Prettier - no JS/CSS files staged."
  newline
fi

# -------------------------------------
# Stylelint
# -------------------------------------
if [ -n "$STAGED_CSS" ]; then
  debug_block "Stylelint input files" "$STAGED_CSS"

  if ! run_step "Stylelint" npx stylelint --color $STAGED_CSS; then
    mark_failed "stylelint"
    > "$TMP_DIR/failed_stylelint"
    for f in $STAGED_CSS; do
      npx stylelint "$f" >/dev/null 2>&1 || echo "$f" >> "$TMP_DIR/failed_stylelint"
    done
  fi
  newline
else
  skip "Skipping Stylelint - no CSS/SCSS files staged."
  newline
fi

# -------------------------------------
# ESLint
# -------------------------------------
if [ -n "$STAGED_JS" ]; then
 debug_block "ESLint input files" "$STAGED_JS"

  if ! run_step "ESLint" npx eslint --color $STAGED_JS; then
    mark_failed "eslint"
    > "$TMP_DIR/failed_eslint"
    for f in $STAGED_JS; do
      npx eslint "$f" >/dev/null 2>&1 || echo "$f" >> "$TMP_DIR/failed_eslint"
    done
  fi
  newline
else
  skip "Skipping ESLint - no JS files staged."
  newline
fi

# -------------------------------------
# PHPCS
# -------------------------------------
if [ -n "$STAGED_PHP" ]; then
debug_block "PHPCS input files" "$STAGED_PHP"

  if ! run_step "PHPCS" "$THEME_DIR/vendor/bin/phpcs" --colors $STAGED_PHP; then
    mark_failed "phpcs"
    > "$TMP_DIR/failed_phpcs"
    for f in $STAGED_PHP; do
      "$THEME_DIR/vendor/bin/phpcs" "$f" >/dev/null 2>&1 || echo "$f" >> "$TMP_DIR/failed_phpcs"
    done
  fi
  newline
else
  skip "Skipping PHPCS - no PHP files staged."
  newline
fi


# -------------------------------------
# Debug code check in PHP files
# -------------------------------------
# -------------------------------------
# Debug code check (warn only, silent if clean)
# -------------------------------------
# -------------------------------------
# Debug code check (warn only, silent if clean)
# -------------------------------------
if [ -n "$STAGED_PHP" ]; then
  DEBUG_FOUND=0

  for f in $STAGED_PHP; do
    MATCHES=$(php -r '
      $code = file_get_contents($argv[1]);
      $tokens = token_get_all($code);
      foreach ($tokens as $t) {
        if (is_array($t) && $t[0] === T_STRING) {
          if (in_array(strtolower($t[1]), ["dbug","var_dump","print_r","die","exit","error_log"])) {
            echo $argv[1].":".$t[2]." ".$t[1]."()\n";
          }
        }
      }
    ' "$THEME_DIR/$f")

    if [ -n "$MATCHES" ]; then
      while IFS= read -r match; do
        warn "Debug code found at $match – please remove before committing to production."
      done <<< "$MATCHES"
      DEBUG_FOUND=1
    fi
  done

  export DEBUG_FOUND
fi



# -------------------------------------
# Final result
# -------------------------------------
# if [ "$ALL_CLEAN" = true ]; then
#   success "All checks passed."
#   exit 0
# fi

if [ "$ALL_CLEAN" = true ]; then
  success "All checks passed."
  debug_block "Final result" "ALL_CLEAN=$ALL_CLEAN"
  debug "=== exit run-checks.sh (all clean) ==="
  exit 0
else
  newline
  debug_block "Final result" "ALL_CLEAN=$ALL_CLEAN
$(env | grep _FAILED=1 || true)"
  debug "=== exit run-checks.sh (failures) ==="
fi
