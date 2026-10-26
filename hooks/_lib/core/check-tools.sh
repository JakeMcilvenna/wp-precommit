#!/bin/bash
source "$CORE_DIR/config.sh"

set_spinner "spinner1"

CACHE_FILE="$TMP_DIR/.toolcheck_cache"

# Invalidate cache if deps folders are missing
if [ ! -d "$THEME_DIR/node_modules" ] || [ ! -d "$THEME_DIR/vendor" ]; then
  rm -f "$CACHE_FILE"
fi

# Skip if cache still valid
if [ -f "$CACHE_FILE" ] && [ "$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))" -lt "$TOOLCHECK_TTL" ]; then
  newline
  skip "Tools recently checked. Skipping..."
  newline
  return 0 2>/dev/null || exit 0
fi

# Quick check: missing deps folders?
MISSING_NODE=false
MISSING_VENDOR=false
[ ! -d "$THEME_DIR/node_modules" ] && MISSING_NODE=true
[ ! -d "$THEME_DIR/vendor" ] && MISSING_VENDOR=true

if $MISSING_NODE || $MISSING_VENDOR; then
  newline
  warn "Dependencies missing:"
  $MISSING_NODE && warn "Missing node_modules (JavaScript dependencies not installed)"
  $MISSING_VENDOR && warn "Missing vendor (PHP dependencies not installed)"
  newline

  read -p "Install them now? [y/N] " -r < /dev/tty
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    $MISSING_NODE && { info "📦 npm install"; (cd "$THEME_DIR" && npm install); newline; }
    $MISSING_VENDOR && { info "📦 composer install"; (cd "$THEME_DIR" && composer install); newline; }
    success "Dependencies installed."
    touch "$CACHE_FILE"
    return 0 2>/dev/null || exit 0
  else
    error "Dependencies missing. Run npm install / composer install."
    exit 1
  fi
fi

MISSING=0
declare -a CMDS STEPS VERSIONS

# npx
CMDS+=("command -v npx >/dev/null")
STEPS+=("npx")
VERSIONS+=("npx --version")

# composer
CMDS+=("command -v composer >/dev/null")
STEPS+=("Composer")
VERSIONS+=("composer --version | awk '{print \$3}'")

# prettier
CMDS+=("[ -x \"$THEME_DIR/node_modules/.bin/prettier\" ]")
STEPS+=("Prettier")
VERSIONS+=("(cd \"$THEME_DIR\" && ./node_modules/.bin/prettier --version)")

# eslint
CMDS+=("[ -x \"$THEME_DIR/node_modules/.bin/eslint\" ]")
STEPS+=("ESLint")
VERSIONS+=("(cd \"$THEME_DIR\" && ./node_modules/.bin/eslint --version)")

# stylelint
CMDS+=("[ -x \"$THEME_DIR/node_modules/.bin/stylelint\" ]")
STEPS+=("Stylelint")
VERSIONS+=("(cd \"$THEME_DIR\" && ./node_modules/.bin/stylelint --version)")

# husky
CMDS+=("[ -f \"$THEME_DIR/node_modules/husky/package.json\" ]")
STEPS+=("Husky")
VERSIONS+=("node -p \"require('$THEME_DIR/node_modules/husky/package.json').version\"")

# phpcs
CMDS+=("[ -x \"$THEME_DIR/vendor/bin/phpcs\" ]")
STEPS+=("PHP_CodeSniffer")
VERSIONS+=("echo v\$($THEME_DIR/vendor/bin/phpcs --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')")

# wpcs
CMDS+=("$THEME_DIR/vendor/bin/phpcs -i | grep -q 'WordPress'")
STEPS+=("WPCS")
VERSIONS+=("grep '\"wp-coding-standards/wpcs\"' -A 1 \"$THEME_DIR/composer.lock\" | grep '\"version\"' | head -n1 | awk -F '\"' '{print \"v\"\$4}'")

# Debug (always fails, for testing)
# CMDS+=("npx --no-install ts-unused-exports --version >/dev/null 2>&1")
# STEPS+=("ts-unused-exports")
# VERSIONS+=("npx --no-install ts-unused-exports --version")

newline
info "🔍 Checking tools..."
start_tool_check

if [ "$MISSING" -eq 1 ]; then
  newline
  error "One or more tools missing."

  NEED_NPM=false
  NEED_COMPOSER=false
  [ ! -x "$THEME_DIR/node_modules/.bin/prettier" ] && NEED_NPM=true
  [ ! -x "$THEME_DIR/node_modules/.bin/eslint" ] && NEED_NPM=true
  [ ! -x "$THEME_DIR/node_modules/.bin/stylelint" ] && NEED_NPM=true
  [ ! -f "$THEME_DIR/node_modules/husky/package.json" ] && NEED_NPM=true
  if [ ! -x "$THEME_DIR/vendor/bin/phpcs" ] || [ ! -x "$THEME_DIR/vendor/bin/phpcbf" ]; then
    NEED_COMPOSER=true
  fi
  ! "$THEME_DIR/vendor/bin/phpcs" -i 2>/dev/null | grep -q 'WordPress' && NEED_COMPOSER=true

  read -p "Install missing deps now? [y/N] " -r < /dev/tty
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    $NEED_NPM && { info "📦 npm install"; (cd "$THEME_DIR" && npm install); newline; }
    $NEED_COMPOSER && { info "📦 composer install"; (cd "$THEME_DIR" && composer install); newline; }
    success "Dependencies installed."
    touch "$CACHE_FILE"
    return 0 2>/dev/null || exit 0
  else
    warn "Skipped install. Run manually:"
    $NEED_NPM && echo " - npm install (in $THEME_DIR)"
    $NEED_COMPOSER && echo " - composer install (in $THEME_DIR)"
    newline
    exit 1
  fi
fi

touch "$CACHE_FILE"
return 0 2>/dev/null || exit 0
