#!/usr/bin/env bash

: '
janus.sh - main script

- handles authentication using auth.sh
- displays a TUI to connect to machines or edit settings
- stub mode: set JANUS_STUB=1 to skip authentication and go straight to the menu
- headless mode: set DIALOG=cmdline and provide USER_LOGIN / USER_PWD env vars
'

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/utils.sh"


# auth
if ! "$DIR/auth.sh"; then
  log "ERROR" "Authentication failed or cancelled. Exiting."
  log "DEBUG" "Session log available at: $JANUS_LOG_FILE"
  exit 1
fi
log "INFO" "Authentication successful. Launching main menu."

# Step 2: Main TUI menu
while true; do
  CHOICE=$(dialog --backtitle "Janus Bastion" --title "Main Menu" \
          --menu "Select an action:" 15 50 5 \
          "1" "Connect to a machine" \
          "2" "View logs" \
          "3" "Quit" \
          3>&1 1>&2 2>&3)

  EXIT_STATUS=$?
  if [ $EXIT_STATUS -ne 0 ]; then
    log WARN "User exited menu with ESC or Cancel"
    echo "DEBUG Session log available at: $JANUS_LOG_FILE"
    break
  fi

  case "$CHOICE" in
    "1")
      log INFO "User selected: Connect to a machine"
      HOST_SELECTED=$("$DIR/connect.sh")
      if [[ $? -eq 0 && -n "$HOST_SELECTED" ]]; then
        dialog --msgbox "Hôte sélectionné : ${HOST_SELECTED}" 6 60
        log INFO "User chose host: ${HOST_SELECTED}"
        # Issue #7 lancera réellement la connexion SSH ici.
      else
        log INFO "connect.sh cancelled or returned empty hostname"
      fi
      ;;
    "2")
      dialog --clear --textbox "$JANUS_LOG_FILE" 22 80
      log INFO "User viewed logs"
      ;;
    "3")
      log INFO "User selected: Quit"
      break
      ;;
    *)
      log WARN "Invalid menu choice: $CHOICE"
      ;;
  esac
done

log INFO "Janus Bastion session ended."
echo "Session log available at: $JANUS_LOG_FILE"
