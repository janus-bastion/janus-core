#!/usr/bin/env bash
# shellcheck disable=SC1091

: '
janus.sh - main script

- handles authentication using auth.sh
- displays a TUI to connect to machines or edit settings
- stub mode: set JANUS_STUB=1 to skip authentication and go straight to the menu
- headless mode: set DIALOG=cmdline and provide USER_LOGIN / USER_PWD env vars
'

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/utils.sh"          # provides log() + load_config
load_config                      # in case global settings are needed here

if [[ "${JANUS_STUB:-0}" != "1" ]]; then
  if ! "$DIR/auth.sh"; then
    log ERROR "Authentication failed or was cancelled – exiting."
    exit 1
  fi
  log INFO "Authentication successful."
else
  # Stub mode: export a dummy user so connect.sh works
  export JANUS_USER="${JANUS_USER:-stubuser}"
  echo "$JANUS_USER" > /tmp/janus_user
  log INFO "Stub mode enabled (JANUS_STUB=1); skipping real authentication."
fi

while true; do
  CHOICE=$(dialog --clear --backtitle "Janus Bastion" \
          --title "Main Menu" \
          --menu "Select an action:" 15 50 5 \
          "1" "Connect to a machine" \
          "2" "View logs" \
          "3" "Quit" \
          3>&1 1>&2 2>&3)

  EXIT_STATUS=$?
  if [[ $EXIT_STATUS -ne 0 ]]; then
    log INFO "User aborted the main menu (ESC/Cancel)."
    break
  fi

  case "$CHOICE" in
    "1")
      log INFO "Menu: Connect to a machine selected."
      HOST_SELECTED=$("$DIR/connect.sh")   # or ./connect2.sh if that’s the filename
      if [[ $? -eq 0 && -n "$HOST_SELECTED" ]]; then
        dialog --backtitle "Janus Bastion" \
               --msgbox "Host selected: ${HOST_SELECTED}" 6 50
        log INFO "User picked host: ${HOST_SELECTED}"
        # ISSUE #7 will actually perform the SSH connection here.
      else
        log INFO "connect.sh was cancelled or returned no host."
      fi
      ;;
    "2")
      # If utils.sh defined JANUS_LOG_FILE, display it; fallback to /var/log/janus.log
      LOG_FILE="${JANUS_LOG_FILE:-/var/log/janus.log}"
      if [[ -f "$LOG_FILE" ]]; then
        dialog --backtitle "Janus Bastion" \
               --title "Session log" \
               --textbox "$LOG_FILE" 22 80
      else
        dialog --backtitle "Janus Bastion" \
               --msgbox "Log file not found: $LOG_FILE" 6 60
      fi
      ;;
    "3")
      log INFO "Menu: Quit selected – exiting."
      break
      ;;
    *)
      log WARN "Unexpected menu choice: $CHOICE"
      ;;
  esac
done

log INFO "Janus Bastion session ended."
