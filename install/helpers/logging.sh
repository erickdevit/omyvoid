start_log_output() {
  # When building the ISO from the host, the host-side tail -f handles progress display.
  # The in-chroot cursor monitor would produce garbled ANSI codes through the chroot pipe.
  if [[ -n ${OMYVOID_ISO_HOST_PROGRESS:-} ]]; then
    return
  fi

  local ANSI_SAVE_CURSOR="\033[s"
  local ANSI_RESTORE_CURSOR="\033[u"
  local ANSI_CLEAR_LINE="\033[2K"
  local ANSI_HIDE_CURSOR="\033[?25l"
  local ANSI_RESET="\033[0m"
  local ANSI_GRAY="\033[90m"

  # Save cursor position and hide cursor
  printf $ANSI_SAVE_CURSOR
  printf $ANSI_HIDE_CURSOR

  (
    local log_lines=20
    local max_line_width=$((LOGO_WIDTH - 4))

    while true; do
      # Read the last N lines into an array
      mapfile -t current_lines < <(tail -n $log_lines "$OMYVOID_INSTALL_LOG_FILE" 2>/dev/null)

      # Build complete output buffer with escape sequences
      output=""
      for ((i = 0; i < log_lines; i++)); do
        line="${current_lines[i]:-}"

        # Truncate if needed
        if (( ${#line} > max_line_width )); then
          line="${line:0:$max_line_width}..."
        fi

        # Add clear line escape and formatted output for each line
        if [[ -n $line ]]; then
          output+="${ANSI_CLEAR_LINE}${ANSI_GRAY}${PADDING_LEFT_SPACES}  → ${line}${ANSI_RESET}\n"
        else
          output+="${ANSI_CLEAR_LINE}${PADDING_LEFT_SPACES}\n"
        fi
      done

      printf "${ANSI_RESTORE_CURSOR}%b" "$output"

      sleep 0.1
    done
  ) &
  monitor_pid=$!
}

stop_log_output() {
  if [[ -n ${monitor_pid:-} ]]; then
    kill $monitor_pid 2>/dev/null || true
    wait $monitor_pid 2>/dev/null || true
    unset monitor_pid
  fi
}

start_install_log() {
  sudo touch "$OMYVOID_INSTALL_LOG_FILE"
  sudo chmod 666 "$OMYVOID_INSTALL_LOG_FILE"

  export OMYVOID_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

  echo "=== Omyvoid Installation Started: $OMYVOID_START_TIME ===" >>"$OMYVOID_INSTALL_LOG_FILE"
  start_log_output
}

stop_install_log() {
  stop_log_output
  show_cursor

  if [[ -n ${OMYVOID_INSTALL_LOG_FILE:-} ]]; then
    OMYVOID_END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "=== Omyvoid Installation Completed: $OMYVOID_END_TIME ===" >> "$OMYVOID_INSTALL_LOG_FILE"
    echo "" >> "$OMYVOID_INSTALL_LOG_FILE"
    echo "=== Installation Time Summary ===" >> "$OMYVOID_INSTALL_LOG_FILE"

    if [[ -n $OMYVOID_START_TIME ]]; then
      OMYVOID_START_EPOCH=$(date -d "$OMYVOID_START_TIME" +%s)
      OMYVOID_END_EPOCH=$(date -d "$OMYVOID_END_TIME" +%s)
      OMYVOID_DURATION=$((OMYVOID_END_EPOCH - OMYVOID_START_EPOCH))

      OMYVOID_MINS=$((OMYVOID_DURATION / 60))
      OMYVOID_SECS=$((OMYVOID_DURATION % 60))

      echo "Omyvoid:    ${OMYVOID_MINS}m ${OMYVOID_SECS}s" >> "$OMYVOID_INSTALL_LOG_FILE"
      echo "Total:       ${OMYVOID_MINS}m ${OMYVOID_SECS}s" >> "$OMYVOID_INSTALL_LOG_FILE"
    fi
    echo "=================================" >> "$OMYVOID_INSTALL_LOG_FILE"

    echo "Installation finished." >> "$OMYVOID_INSTALL_LOG_FILE"
  fi
}

run_logged() {
  local script="$1"

  export CURRENT_SCRIPT="$script"

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: $script" >>"$OMYVOID_INSTALL_LOG_FILE"

  # Use bash -c to create a clean subshell
  bash -c "source '$script'" </dev/null >>"$OMYVOID_INSTALL_LOG_FILE" 2>&1

  local exit_code=$?

  if (( exit_code == 0 )); then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed: $script" >>"$OMYVOID_INSTALL_LOG_FILE"
    unset CURRENT_SCRIPT
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: $script (exit code: $exit_code)" >>"$OMYVOID_INSTALL_LOG_FILE"
  fi

  return $exit_code
}
