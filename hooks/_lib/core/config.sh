#!/bin/bash
set -euo pipefail

# --------------------------------------------------
# Shared paths
# --------------------------------------------------

# Get shared paths
source "$(git rev-parse --show-toplevel)/wp-content/themes/theme/.husky/hooks/_lib/core/paths.sh"


# Ensure tmp exists
mkdir -p "$TMP_DIR"

# --------------------------------------------------
# Settings
# --------------------------------------------------

# TTL for cached tool checks (in seconds)
TOOLCHECK_TTL=21600 # 6 hours

# --------------------------------------------------
# Helpers
# --------------------------------------------------

cleanup_caches() {
  # Delete all caches except .toolcheck_cache
  find "$TMP_DIR" -type f -name '*.cache' ! -name '.toolcheck_cache' -delete
}

# --------------------------------------------------
# Shared libs
# --------------------------------------------------
source "$UI_DIR/colors.sh"
source "$UI_DIR/output.sh"
source "$UI_DIR/spinner.sh"
source "$CORE_DIR/runner.sh"

# --------------------------------------------------
# Exports
# --------------------------------------------------

export REPO_ROOT THEME_DIR HUSKY_DIR HOOKS_DIR LIB_DIR TMP_DIR PRECOMMIT_HOOK
export TOOLCHECK_TTL
export -f cleanup_caches
