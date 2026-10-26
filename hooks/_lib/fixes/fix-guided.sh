#!/bin/bash
source "$CORE_DIR/config.sh"

set_spinner "spinner1"

info "🔧 Starting guided fix mode..."
newline

FILES_WITH_ISSUES=0
PHPCS_FAILED=0
STYLELINT_FAILED=0
ESLINT_FAILED=0
PRETTIER_FAILED=0
PHPCS_SKIPPED=0
STYLELINT_SKIPPED=0
ESLINT_SKIPPED=0
PRETTIER_SKIPPED=0

AUTO_FIX_ATTEMPTED=${AUTO_FIX_ATTEMPTED:-0} # from fix-auto

# Load failed files from run-checks.sh or fix-auto.sh
FAILED_JS=$(cat "$TMP_DIR/failed_eslint" 2>/dev/null || echo "")
FAILED_CSS=$(cat "$TMP_DIR/failed_stylelint" 2>/dev/null || echo "")
FAILED_PHP=$(cat "$TMP_DIR/failed_phpcs" 2>/dev/null || echo "")

# Sort staged files by type
SORTED_FILES=$(for file in $STAGED_FILES; do
  case "$file" in
    *.scss|*.css) echo "1:$file" ;;
    *.js) echo "2:$file" ;;
    *.php) echo "3:$file" ;;
  esac
done | sort | cut -d: -f2)

LAST_EXT=""

for file in $SORTED_FILES; do
  extension="${file##*.}"
  should_process=false

  if [[ "$extension" = "js" ]]; then
    for f in $FAILED_JS; do [[ "$f" == "$file" ]] && should_process=true; done
  elif [[ "$extension" =~ ^(scss|css)$ ]]; then
    for f in $FAILED_CSS; do [[ "$f" == "$file" ]] && should_process=true; done
  elif [[ "$extension" = "php" ]]; then
    for f in $FAILED_PHP; do [[ "$f" == "$file" ]] && should_process=true; done
  fi

  [[ "$should_process" == false ]] && continue

  SKIP_LINT=0
  [[ "$extension" != "$LAST_EXT" ]] && newline && LAST_EXT="$extension"

  # -----------------------------
  # Stylelint
  # -----------------------------
  if [[ "$extension" =~ ^(scss|css)$ ]]; then
    AUTO_FIX_TRIED_THIS_FILE=0
    while :; do
      if [ "$SKIP_LINT" != "1" ]; then
        if run_spinner_step "Stylelint on $file" "npx stylelint --color \"$file\""; then
          git add "$file"; STYLELINT_FAILED=0; break
        fi
      fi

      if [ "$AUTO_FIX_ATTEMPTED" -eq 1 ] || [ "$AUTO_FIX_TRIED_THIS_FILE" -eq 1 ]; then
        hr
        echo "Fix this file with Stylelint? (s = skip, r = manually fix then recheck, a = abort commit)"
        hr
      else
        hr
        echo "Fix this file with Stylelint? (y = auto-fix, s = skip, r = manually fix then recheck, a = abort commit)"
        hr
      fi
      read -rp "> " < /dev/tty fix

      if [ "$fix" = "y" ] && [ "$AUTO_FIX_ATTEMPTED" -eq 0 ] && [ "$AUTO_FIX_TRIED_THIS_FILE" -eq 0 ]; then
        AUTO_FIX_TRIED_THIS_FILE=1
        TMP_CHECK_OUT="$TMP_DIR/stylelint.$(basename "$file").out"
        npx stylelint --fix "$file" >/dev/null 2>&1 || true
        npx stylelint "$file" >"$TMP_CHECK_OUT" 2>&1 || true

        if ! grep -q "✖" "$TMP_CHECK_OUT"; then
          success "Stylelint fixed all issues in $file."
          git add "$file"; STYLELINT_FAILED=0; break
        else
          warn "Stylelint fixed some issues, but others remain."
          cat "$TMP_CHECK_OUT"
          STYLELINT_FAILED=1; FILES_WITH_ISSUES=1; SKIP_LINT=1
          continue
        fi
      elif [ "$fix" = "r" ]; then
        read -rp "🕒 Press enter to recheck..." < /dev/tty
        if run_spinner_step "Stylelint recheck on $file" "npx stylelint \"$file\""; then
          git add "$file"
          STYLELINT_FAILED=0
          FILES_WITH_ISSUES=0   # reset since issues are gone
          break
        else
          STYLELINT_FAILED=1; FILES_WITH_ISSUES=1
        fi
      elif [ "$fix" = "s" ]; then
        STYLELINT_SKIPPED=1; break
      elif [ "$fix" = "a" ]; then
        error "Commit aborted by user."; exit 1
      fi
    done

  # -----------------------------
  # ESLint
  # -----------------------------
  elif [ "$extension" = "js" ]; then
    AUTO_FIX_TRIED_THIS_FILE=0
    while :; do
      if [ "$SKIP_LINT" != "1" ]; then
        if run_spinner_step "ESLint on $file" "npx eslint --color \"$file\""; then
          git add "$file"; ESLINT_FAILED=0; break
        fi
      fi

      if [ "$AUTO_FIX_ATTEMPTED" -eq 1 ] || [ "$AUTO_FIX_TRIED_THIS_FILE" -eq 1 ]; then
        hr
        echo "Fix this file with ESLint? (s = skip, r = manually fix then recheck, a = abort commit)"
        hr
      else
        hr
        echo "Fix this file with ESLint? (y = auto-fix, s = skip, r = manually fix then recheck, a = abort commit)"
        hr
      fi
      read -rp "> " < /dev/tty fix

      if [ "$fix" = "y" ] && [ "$AUTO_FIX_ATTEMPTED" -eq 0 ] && [ "$AUTO_FIX_TRIED_THIS_FILE" -eq 0 ]; then
        AUTO_FIX_TRIED_THIS_FILE=1
        TMP_CHECK_OUT="$TMP_DIR/eslint.$(basename "$file").out"
        npx eslint --fix "$file" >/dev/null 2>&1 || true
        npx eslint "$file" --color >"$TMP_CHECK_OUT" 2>&1 || true

        if ! grep -q "✖" "$TMP_CHECK_OUT"; then
          success "ESLint fixed all issues in $file."
          git add "$file"; ESLINT_FAILED=0; break
        else
          warn "ESLint fixed some issues, but others remain."
          cat "$TMP_CHECK_OUT"
          ESLINT_FAILED=1; FILES_WITH_ISSUES=1; SKIP_LINT=1
          continue
        fi
      elif [ "$fix" = "r" ]; then
        read -rp "🕒 Press enter to recheck..." < /dev/tty
        if run_spinner_step "ESLint recheck on $file" "npx eslint --color \"$file\""; then
          git add "$file"
          ESLINT_FAILED=0
          FILES_WITH_ISSUES=0   # reset since issues are gone
          break
        else
          ESLINT_FAILED=1; FILES_WITH_ISSUES=1
        fi
      elif [ "$fix" = "s" ]; then
        ESLINT_SKIPPED=1; break
      elif [ "$fix" = "a" ]; then
        error "Commit aborted by user."; exit 1
      fi
    done

  # -----------------------------
  # PHPCS
  # -----------------------------
  elif [ "$extension" = "php" ]; then
    AUTO_FIX_TRIED_THIS_FILE=0
    while :; do
      if [ "$SKIP_LINT" != "1" ]; then
        if run_spinner_step "PHPCS on $file" "vendor/bin/phpcs \"$file\""; then
          git add "$file"; PHPCS_FAILED=0; break
        fi
      fi

      if [ "$AUTO_FIX_ATTEMPTED" -eq 1 ] || [ "$AUTO_FIX_TRIED_THIS_FILE" -eq 1 ]; then
        hr
        echo "Fix this file with PHPCS? (s = skip, r = manually fix then recheck, a = abort commit)"
        hr
      else
        hr
        echo "Fix this file with PHPCS? (y = auto-fix, s = skip, r = manually fix then recheck, a = abort commit)"
        hr
      fi
      read -rp "> " < /dev/tty fix

      if [ "$fix" = "y" ] && [ "$AUTO_FIX_ATTEMPTED" -eq 0 ] && [ "$AUTO_FIX_TRIED_THIS_FILE" -eq 0 ]; then
        AUTO_FIX_TRIED_THIS_FILE=1
        vendor/bin/phpcbf "$file" >/dev/null 2>&1 || true
        git add "$file"

        if run_spinner_step "PHPCS recheck on $file" "vendor/bin/phpcs \"$file\""; then
          success "PHPCBF fixed all issues in $file."
          PHPCS_FAILED=0; break
        else
          warn "PHPCBF could not fix all issues automatically."
          vendor/bin/phpcs "$file" || true
          PHPCS_FAILED=1; FILES_WITH_ISSUES=1; SKIP_LINT=1
          continue
        fi
      elif [ "$fix" = "r" ]; then
        read -rp "🕒 Press enter to recheck..." < /dev/tty
        if run_spinner_step "PHPCS recheck on $file" "vendor/bin/phpcs \"$file\""; then
          git add "$file"
          PHPCS_FAILED=0
          FILES_WITH_ISSUES=0   # reset since issues are gone
          break
        else
          vendor/bin/phpcs "$file" || true
          PHPCS_FAILED=1; FILES_WITH_ISSUES=1
          continue
        fi
      elif [ "$fix" = "s" ]; then
        PHPCS_SKIPPED=1; break
      elif [ "$fix" = "a" ]; then
        error "Commit aborted by user."; exit 1
      fi
    done
  fi
done

# Summary
source "$UI_DIR/summary.sh"

# Final decision
if [ "$STYLELINT_SKIPPED" -eq 1 ] || [ "$ESLINT_SKIPPED" -eq 1 ] || [ "$PHPCS_SKIPPED" -eq 1 ]; then
  hr
  warn "${BOLD}Some files were skipped but commit will proceed anyway.${RESET}"
  newline
  exit 0
fi

if [ "$FILES_WITH_ISSUES" -eq 0 ]; then
  newline
  success "All files passed after guided fixes. Committing..."
  exit 0
else
  newline
  error "Commit blocked: some issues could not be fixed or were skipped."
  warn "Please review and fix manually, then try again."
  exit 1
fi
