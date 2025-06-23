#!/usr/bin/env bash
# shellcheck disable=SC1091

: '
janus.sh – main entry point for the Janus bastion TUI

• Launches auth.sh (unless JANUS_STUB=1).
• Displays a dialog menu:
    1. Connect to a machine   →  connect.sh  →  jump_connect.sh
    2. View logs              →  tail or view JANUS_LOG_FILE
    3. Quit
• Uses utils.sh for logging and configuration
'

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/utils.sh"
load_config

# ────────────────────────────────────────────────────────────────────────────
# 1. Authentication (skippable via JANUS_STUB)
# ────────────────────────────────────────────────────────────────────────────
if [[ "${JANUS_STUB:-0}" != "1" ]]; then
  if ! "$DIR/auth.sh"; then
    log ERROR "Authentication failed or cancelled."
    exit 1
  fi
  log INFO "Authentication successful."
else
  export JANUS_USER="${JANUS_USER:-stubuser}"
  echo "$JANUS_USER" > /tmp/janus_user
  log INFO "Stub mode: skipping authentication, user=${JANUS_USER}"
fi

# ────────────────────────────────────────────────────────────────────────────
# 2. Main menu loop
# ────────────────────────────────────────────────────────────────────────────
while true; do
  CHOICE=$(dialog --clear --backtitle "Janus Bastion" \
          --title "Main Menu" \
          --menu "Select an action:" 15 55 5 \
          "1" "Connect to a machine" \
          "2" "View logs" \
          "3" "Quit" \
          3>&1 1>&2 2>&3)
  [[ $? -ne 0 ]] && break   # ESC/Cancel exits

  case "$CHOICE" in
    1)
      log INFO "Menu → Connect to a machine"
      HOST_SELECTED=$("$DIR/connect.sh")
      if [[ $? -eq 0 && -n "$HOST_SELECTED" ]]; then
        log INFO "Host chosen: $HOST_SELECTED"
        "$DIR/jump_connect.sh" "$HOST_SELECTED"
      else
        log INFO "connect.sh cancelled or returned nothing"
      fi
      ;;
    2)
      LOG_FILE="${JANUS_LOG_FILE:-/var/log/janus.log}"
      if [[ -f "$LOG_FILE" ]]; then
        dialog --backtitle "Janus Bastion" --title "Session log" \
               --textbox "$LOG_FILE" 22 80
      else
        dialog --msgbox "Log file not found: $LOG_FILE" 6 60
      fi
      ;;
    3)  break ;;
    *)  log WARN "Unexpected menu choice: $CHOICE" ;;
  esac
done

log INFO "Session ended."
exit 0
