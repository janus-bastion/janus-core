#!/bin/bash
# ------------------------------------------------------------------------------
# utils.sh - Shared utility functions for Janus Bastion
# ------------------------------------------------------------------------------

# This script must be sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This script must be sourced, not executed directly." >&2
  exit 1
fi

# Create (or reuse) the session log file.
# ${VAR:-} avoids “unbound variable” errors under `set -u`.
if [[ -z "${JANUS_LOG_FILE:-}" ]]; then
  JANUS_LOG_FILE="$(mktemp /tmp/janus-log-XXXXXX.log)"

  {
    echo "=== Janus Session Log ==="
    echo "Log file located at: $JANUS_LOG_FILE"
    echo "Session start: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================="
  } >> "$JANUS_LOG_FILE"

  echo "[INFO] Session log file created at: $JANUS_LOG_FILE" >&2

fi
# Export so child scripts inherit the same file path
export JANUS_LOG_FILE

# Logging function
# Usage: log LEVEL MESSAGE
log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  local line="[$timestamp] [$level] $message"

  # Write to stderr and append to the shared log file
  echo "$line" >&2
  echo "$line" >> "$JANUS_LOG_FILE"
}


# Error handler
# Usage: die "message"
die() {
  log "ERROR" "$*"
  exit 1
}

# Configuration loader
# Usage: load_config [path]
load_config() {
  local config_path="${1:-$DIR/../config/bastion.conf}"

  if [[ -f "$config_path" ]]; then
    # shellcheck disable=SC1090
    source "$config_path"
    log "DEBUG" "Loaded configuration from $config_path"
  else
    log "WARN" "Configuration file not found: $config_path. Proceeding with defaults."
  fi
}
