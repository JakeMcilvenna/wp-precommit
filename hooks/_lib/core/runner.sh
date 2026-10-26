#!/bin/bash -e
# Task runners

source "$CORE_DIR/paths.sh"
source "$UI_DIR/spinner.sh"
source "$UI_DIR/colors.sh"
source "$UI_DIR/output.sh"

# -----------------------------
# Tool check runner (parallel)
# -----------------------------
start_tool_check() {
  local num_steps=${#CMDS[@]} i
  declare -a PIDS STATUSES CACHE_FILES VERSIONS_OUT

  tput civis
  echo ""

  local STATUS_FILE="$TMP_DIR/.tool_status"
  mkdir -p "$TMP_DIR"
  : > "$STATUS_FILE"

  for (( i=0; i<num_steps; i++ )); do
    CACHE_FILES[i]=$(make_cache_file "${STEPS[i]}")
    : > "${CACHE_FILES[i]}"

    echo "[   ] ${STEPS[i]} ..."

    (
      if eval "${CMDS[i]}" &>/dev/null; then
        local ver
        ver="$(eval "${VERSIONS[i]}" 2>/dev/null)"
        echo "${i}:0:${ver}" >> "$STATUS_FILE"
      else
        echo "${i}:1:" >> "$STATUS_FILE"
      fi
    ) &> "${CACHE_FILES[i]}" &
    PIDS[i]=$!
    STATUSES[i]=0
  done

  local all_done=0 frame_index=0
  while [ $all_done -lt $num_steps ]; do
    all_done=0
    while IFS=":" read -r idx code ver; do
      if [ "${STATUSES[idx]}" -eq 0 ]; then
        if [ "$code" -eq 0 ]; then
          STATUSES[idx]=1
          VERSIONS_OUT[idx]="$ver"
        else
          STATUSES[idx]=2
        fi
      fi
    done < "$STATUS_FILE"

    for (( i=0; i<num_steps; i++ )); do
      [ "${STATUSES[i]}" -ne 0 ] && all_done=$((all_done+1))
    done

    tput cuu ${num_steps}
    for (( i=0; i<num_steps; i++ )); do
      if [ "${STATUSES[i]}" -eq 0 ]; then
        local frame="${FRAME[$((frame_index % ${#FRAME[@]}))]}"
        printf "\r\033[K[ %s ] %s ...\n" "$frame" "${STEPS[i]}"
      elif [ "${STATUSES[i]}" -eq 1 ]; then
        printf "\r\033[K${GREEN}[ ✔ ]${RESET} %s %s\n" "${STEPS[i]}" "${VERSIONS_OUT[i]}"
      else
        printf "\r\033[K${RED}[ ✘ ]${RESET} %s\n" "${STEPS[i]}"
      fi
    done

    sleep "$FRAME_INTERVAL"
    frame_index=$((frame_index+1))
  done

  for (( i=0; i<num_steps; i++ )); do
    [ "${STATUSES[i]}" -eq 2 ] && MISSING=1
  done

  finish_spinner
  echo ""
}

# -----------------------------
# Step runners
# -----------------------------
run_step() {
  local label="$1"; shift
  local cmd=("$@")
  local CACHE_FILE
  CACHE_FILE=$(make_cache_file "$label")

  tput civis
  ("${cmd[@]}") >"$CACHE_FILE" 2>&1 &
  local pid=$!
  spin_loop "$pid" "$label" ""
  wait "$pid"; local status=$?
  finish_spinner

  if [ $status -eq 0 ]; then
    success "$label passed – no issues found"
  else
    warn "$label reported issues – see details below"
    cat "$CACHE_FILE"
  fi
  return $status
}

recheck_step() {
  local label="$1"; shift
  local cmd=("$@")
  local CACHE_FILE
  CACHE_FILE=$(make_cache_file "$label" "recheck.cache")

  tput civis
  ("${cmd[@]}") >"$CACHE_FILE" 2>&1 &
  local pid=$!
  spin_loop "$pid" "$label" "Rechecking "
  wait "$pid"; local status=$?
  finish_spinner

  if [ $status -eq 0 ]; then
    success "$label passed after fix"
  else
    error "$label issues remain – could not be automatically fixed"
    cat "$CACHE_FILE"
  fi
  return $status
}

run_fix_and_check_step() {
  local label="$1"
  local -a fix_cmd=("${!2}")
  local -a check_cmd=("${!3}")
  local failure_flag="$4"
  local CACHE_FILE
  CACHE_FILE=$(make_cache_file "$label" "fix.cache")

  local before_fix=$(git diff --name-only)

  tput civis
  ("${fix_cmd[@]}") >"$CACHE_FILE" 2>&1 &
  spin_loop $! "$label" "Running "
  wait $!

  ("${check_cmd[@]}") >"$CACHE_FILE" 2>&1 &
  spin_loop $! "$label" "Checking "
  wait $!; local status=$?
  finish_spinner

  local after_fix=$(git diff --name-only)

  if [ $status -eq 0 ]; then
    if [ "$before_fix" != "$after_fix" ]; then
      success "$label issues fixed – working tree updated"
    else
      skip "$label already clean – no changes made"
    fi
    eval "$failure_flag=''"
  else
    if [ "$before_fix" != "$after_fix" ]; then
      warn "$label partially fixed – some issues remain"
    else
      error "$label auto-fix failed – manual intervention needed"
    fi
    cat "$CACHE_FILE"; eval "$failure_flag=1"
  fi
  return $status
}

run_php_fix_and_check_step() {
  local -a fix_cmd=("${!1}")
  local -a check_cmd=("${!2}")
  local failure_flag="$3"
  local label="PHPCBF/PHPCS"
  local FIX_FILE CHECK_FILE
  FIX_FILE=$(make_cache_file "$label" "fix.cache")
  CHECK_FILE=$(make_cache_file "$label" "check.cache")

  local before_fix=$(git diff --name-only)

  tput civis
  ("${fix_cmd[@]}") >"$FIX_FILE" 2>&1 &
  spin_loop $! "PHPCBF" "Running "
  wait $!

  ("${check_cmd[@]}") >"$CHECK_FILE" 2>&1 &
  spin_loop $! "PHPCS" "Running "
  wait $!; local status=$?
  finish_spinner

  local after_fix=$(git diff --name-only)

  if [ $status -eq 0 ]; then
    if [ "$before_fix" != "$after_fix" ]; then
      success "$label issues fixed – working tree updated"
    else
      skip "$label already clean – no changes made"
    fi
    eval "$failure_flag=''"
  else
    if [ "$before_fix" != "$after_fix" ]; then
      warn "$label partially fixed – some issues remain"
    else
      warn "$label reported issues – see details below"
    fi
    cat "$CHECK_FILE"; eval "$failure_flag=1"
  fi
  return $status
}

run_spinner_step() {
  local label="$1"
  local cmd="$2"
  local CACHE_FILE
  CACHE_FILE=$(make_cache_file "$label")

  tput civis
  (eval "$cmd") >"$CACHE_FILE" 2>&1 &
  spin_loop $! "$label" ""
  wait $!; local status=$?
  finish_spinner

  if [ $status -eq 0 ]; then
    success "$label passed – no issues found"
  else
    warn "$label reported issues – see details below"
    cat "$CACHE_FILE"
  fi
  return $status
}
