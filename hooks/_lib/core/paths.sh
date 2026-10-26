#!/bin/bash
set -euo pipefail

# Repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Theme dir
THEME_DIR="$REPO_ROOT/wp-content/themes/theme"

# Husky dirs
HUSKY_DIR="$THEME_DIR/.husky"
HOOKS_DIR="$HUSKY_DIR/hooks"
LIB_DIR="$HOOKS_DIR/_lib"
TMP_DIR="$HUSKY_DIR/tmp"

# Sub dirs
CORE_DIR="$LIB_DIR/core"
UI_DIR="$LIB_DIR/ui"
FIXES_DIR="$LIB_DIR/fixes"

# Ensure tmp dir exists
mkdir -p "$TMP_DIR"

# Export for consistency
export REPO_ROOT THEME_DIR HUSKY_DIR HOOKS_DIR LIB_DIR TMP_DIR CORE_DIR UI_DIR FIXES_DIR  
