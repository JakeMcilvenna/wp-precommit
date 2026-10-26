#!/bin/bash

source "$CORE_DIR/config.sh"

newline
echo "${BOLD}🧾 Summary of results:${RESET}"
hr

# Prettier
if [ -n "$STAGED_JS" ] || [ -n "$STAGED_CSS" ]; then
  if [ "${PRETTIER_SKIPPED:-0}" -eq 1 ]; then
    warn "Prettier – some files skipped (may still contain issues)"
  elif [ "${PRETTIER_FAILED:-0}" -eq 1 ]; then
    error "Prettier – issues remain"
  else
    success "Prettier – passed"
  fi
else
  skip "Prettier – no JS/CSS files"
fi

# Stylelint
if [ -n "$STAGED_CSS" ]; then
  if [ "${STYLELINT_SKIPPED:-0}" -eq 1 ]; then
    warn "Stylelint – some files skipped (may still contain issues)"
  elif [ "${STYLELINT_FAILED:-0}" -eq 1 ]; then
    error "Stylelint – issues remain"
  else
    success "Stylelint – passed"
  fi
else
  skip "Stylelint – no CSS/SCSS files"
fi

# ESLint
if [ -n "$STAGED_JS" ]; then
  if [ "${ESLINT_SKIPPED:-0}" -eq 1 ]; then
    warn "ESLint – some files skipped (may still contain issues)"
  elif [ "${ESLINT_FAILED:-0}" -eq 1 ]; then
    error "ESLint – issues remain"
  else
    success "ESLint – passed"
  fi
else
  skip "ESLint – no JS files"
fi

# PHP CodeSniffer
if [ -n "$STAGED_PHP" ]; then
  if [ "${PHPCS_SKIPPED:-0}" -eq 1 ]; then
    warn "PHP CodeSniffer – some files skipped (may still contain issues)"
  elif [ "${PHPCS_FAILED:-0}" -eq 1 ]; then
    error "PHP CodeSniffer – issues remain"
  else
    success "PHP CodeSniffer – passed"
  fi
else
  skip "PHP CodeSniffer – no PHP files"
fi


# Debug code check in PHP files
if [ "${DEBUG_FOUND:-0}" -eq 1 ]; then
  warn "Debug code – found in staged PHP files (please remove before production)"
fi