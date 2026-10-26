#!/bin/bash
source "$CORE_DIR/config.sh"

info "get-staged.sh: running..."
newline

debug "=== enter script ==="

# Include deletions so we can treat "only deletes" as a no-check case
ALL_STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMRD || true)
debug_block "Step 1: ALL_STAGED_FILES" "$ALL_STAGED_FILES"

# If nothing is staged, treat as nothing to check (not an error)
if [ -z "$ALL_STAGED_FILES" ]; then
  success "No staged files. Proceeding with commit."
  export STAGED_FILES=""
  debug "exit early – no staged files"
  return 0 2>/dev/null || exit 0
fi

# Theme path relative to repo root
THEME_REL=$(realpath --relative-to="$REPO_ROOT" "$THEME_DIR")

# Paths context
debug_block "Step 2: Paths context" "REPO_ROOT=$REPO_ROOT
THEME_DIR=$THEME_DIR
THEME_REL=$THEME_REL"

# Filter to only files under THEME_REL and strip the prefix — using awk so no pipefail explosions
REL_FILES=$(
  printf "%s\n" "$ALL_STAGED_FILES" |
  awk -v p="${THEME_REL}/" 'index($0,p)==1 { sub("^"p,""); print }'
)
debug_block "Step 3: REL_FILES after prefix strip" "$REL_FILES"

# Drop deleted files (keep only ones that still exist)
if [ -n "$REL_FILES" ]; then
  REL_FILES=$(
    printf "%s\n" "$REL_FILES" | while read -r f; do
      [ -f "$THEME_DIR/$f" ] && printf "%s\n" "$f"
    done
  )
fi
debug_block "Step 4: REL_FILES after drop deleted" "$REL_FILES"

# Subsets (guard each grep so -e doesn’t nuke us when empty)
# STAGED_JS=$(printf "%s\n" "$REL_FILES" | grep '\.js$' 2>/dev/null || true)
# STAGED_CSS=$(printf "%s\n" "$REL_FILES" | grep -E '\.(scss|css)$' 2>/dev/null || true)
# STAGED_PHP=$(printf "%s\n" "$REL_FILES" | grep '\.php$' 2>/dev/null || true)
# Subsets
STAGED_JS=$(echo "$REL_FILES" | grep '\.js$' || true)
STAGED_CSS=$(echo "$REL_FILES" | grep -E '\.(scss|css)$' || true)
STAGED_PHP=$(echo "$REL_FILES" | grep '\.php$' || true)

subset_report=""
[ -n "$STAGED_JS" ] && subset_report+="STAGED_JS=$STAGED_JS"$'\n'
[ -n "$STAGED_CSS" ] && subset_report+="STAGED_CSS=$STAGED_CSS"$'\n'
[ -n "$STAGED_PHP" ] && subset_report+="STAGED_PHP=$STAGED_PHP"
debug_block "Step 5: Subsets" "$subset_report"

# Export main and subsets (collapse to empty string if all subsets are empty)
export ALL_STAGED_FILES="$REL_FILES"
export STAGED_JS
export STAGED_CSS
export STAGED_PHP
export STAGED_FILES="$(printf "%s\n%s\n%s\n" "$STAGED_JS" "$STAGED_CSS" "$STAGED_PHP" | sed '/^$/d')"
debug_block "Step 6: Final STAGED_FILES" "$STAGED_FILES"

# If nothing relevant in theme, let the caller skip checks entirely
if [ -z "$STAGED_FILES" ]; then
  success "No theme JS/CSS/SCSS/PHP to check (only deletions or files outside theme)."
  newline
  debug "exit – no relevant files"
  # Leave STAGED_FILES empty; pre-commit has a guard that exits 0
  return 0 2>/dev/null || exit 0
fi


debug "=== exit script ==="
