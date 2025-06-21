#!/usr/bin/env bash

: '
janus.sh - main script

- handles authentication using auth.sh
- displays a TUI to connect to machines or view logs
'

set -euo pipefail

echo -e "       █████   █████████   ██████   █████ █████  █████  █████████ \n      ░░███   ███░░░░░███ ░░██████ ░░███ ░░███  ░░███  ███░░░░░███\n       ░███  ░███    ░███  ░███░███ ░███  ░███   ░███ ░███    ░░░ \n       ░███  ░███████████  ░███░░███░███  ░███   ░███ ░░█████████ \n       ░███  ░███░░░░░███  ░███ ░░██████  ░███   ░███  ░░░░░░░░███\n ███   ░███  ░███    ░███  ░███  ░░█████  ░███   ░███  ███    ░███\n░░████████   █████   █████ █████  ░░█████ ░░████████  ░░█████████ \n ░░░░░░░░   ░░░░░   ░░░░░ ░░░░░    ░░░░░   ░░░░░░░░    ░░░░░░░░
"
./scripts/auth.sh
if [ $? -ne 0 ]; then
  echo "Authentication failed or cancelled. Exiting."
  exit 1
fi

while true; do
  CHOICE=$(dialog --backtitle "Janus Bastion" --title "Main Menu" \
    --menu "Select an action:" 15 50 5 \
    "1" "Connect to a machine" \
    "2" "Settings" \
    "3" "Quit" \
    3>&1 1>&2 2>&3)

  EXIT_STATUS=$?
  if [ $EXIT_STATUS -ne 0 ]; then
    # Non-zero exit code => user pressed ESC or Cancel
    break
  fi

  # 3. Handle the user's choice (placeholders for now)
  case "$CHOICE" in
    "1")
      dialog --msgbox "Connect to a machine - not implemented yet." 6 50
      ;;
    "2")
      dialog --msgbox "Settings - not implemented yet." 6 50
      ;;
    "3")
      break
      ;;
  esac
done

clear
echo "Goodbye!"
