#!/usr/bin/env bash
# shellcheck disable=SC1091

: '
connect.sh – TUI that lists Linux hosts accessible to the authenticated user

• Reads the username stored by auth.sh in /tmp/janus_user
• Loads DB connection parameters via utils.sh / bastion.conf
• Queries janus_db for (hostname, ip, description) of allowed hosts
• Shows the list in a dialog --menu
• Prints the chosen hostname to stdout; exits 0 on OK, 1 on Cancel
'

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/utils.sh"
load_config                       # DB_HOST, DB_USER, DB_PASS, DB_NAME

# ── Determine logged-in Janus user ─────────────────────────────
if [[ -z "${JANUS_USER:-}" && -f /tmp/janus_user ]]; then
  JANUS_USER=$(< /tmp/janus_user)
  export JANUS_USER
fi

if [[ -z "${JANUS_USER:-}" ]]; then
  dialog --backtitle "Janus Bastion" \
         --msgbox "User not authenticated.\nRun auth.sh first." 7 60
  exit 1
fi

# ── Query MySQL for accessible hosts ───────────────────────────
SQL_QUERY="
SELECT DISTINCT
       h.hostname,
       CONCAT_WS(' - ', INET_NTOA(h.ip_addr), h.description) AS info
FROM hosts         h
JOIN services      s  ON s.host_id   = h.id
JOIN access_rules  ar ON ar.service_id = s.id
JOIN users         u  ON u.id        = ar.user_id
WHERE u.username = '${JANUS_USER}'
  AND ar.allow   = 1;
"

mapfile -t rows < <(
  mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" \
        --password="${DB_PASS}" --silent --skip-column-names \
        -e "$SQL_QUERY" "${DB_NAME}"
)

if [[ ${#rows[@]} -eq 0 ]]; then
  dialog --backtitle "Janus Bastion" \
         --msgbox "No machines available for user '${JANUS_USER}'." 6 60
  exit 1
fi

# ── Build dialog menu ──────────────────────────────────────────
declare -a menu_items
for line in "${rows[@]}"; do
  IFS=$'\t' read -r host info <<< "$line"
  menu_items+=("$host" "$info")
done

# ── Show menu and capture selection ────────────────────────────
CHOSEN_HOST=$(dialog --clear --backtitle "Janus Bastion" \
                     --title "Select a machine" \
                     --menu "Machines accessible for '${JANUS_USER}':" 15 70 \
                     ${#menu_items[@]} "${menu_items[@]}" \
                     --stdout)
EXIT_CODE=$?   # 0 = OK, 1 = Cancel/ESC

if [[ $EXIT_CODE -eq 0 && -n "$CHOSEN_HOST" ]]; then
  echo "$CHOSEN_HOST"
  exit 0
else
  exit 1
fi
