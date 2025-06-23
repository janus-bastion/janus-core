#!/usr/bin/env bash

: '
connect.sh - TUI list of Linux hosts accessible to the authenticated user

- reads the username saved by auth.sh in /tmp/janus_user
- loads DB connection parameters via utils.sh / bastion.conf
- queries janus_db to obtain (hostname, ip, description) of allowed hosts
- shows the list in a dialog --menu
- prints the chosen hostname to stdout (no SSH yet – handled in issue #7)
'

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/utils.sh"
load_config                       # sets DB_HOST / DB_PORT / DB_USER / DB_PASS / DB_NAME

if [[ -z "${JANUS_USER:-}" ]]; then
  if [[ -f /tmp/janus_user ]]; then
    JANUS_USER=$(< /tmp/janus_user)
    export JANUS_USER
  fi
fi

if [[ -z "${JANUS_USER:-}" ]]; then
  dialog --backtitle "Janus Bastion" \
         --msgbox "Utilisateur non authentifié.\nVeuillez exécuter auth.sh avant." 7 60
  exit 1
fi

SQL_QUERY="
SELECT DISTINCT
       h.hostname,
       CONCAT(INET6_NTOA(h.ip_addr),
              IF(h.description IS NOT NULL AND h.description <> '',
                 CONCAT(' - ', h.description), ''))
FROM hosts AS h
JOIN services      AS s  ON s.host_id   = h.id
JOIN access_rules  AS ar ON ar.service_id = s.id
JOIN users         AS u  ON u.id        = ar.user_id
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
         --msgbox "Aucune machine accessible pour l'utilisateur '${JANUS_USER}'." 6 60
  exit 1
fi

declare -a menu_items
for line in "${rows[@]}"; do
  IFS=$'\t' read -r host info <<< "$line"
  menu_items+=("$host" "$info")
done

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

dialog --clear --backtitle "Janus Bastion" \
       --title "Sélectionnez une machine" \
       --menu "Machines accessibles pour '${JANUS_USER}':" 15 70 \
       ${#menu_items[@]} "${menu_items[@]}" 2> "$tmpfile"

if [[ $? -eq 0 ]]; then
  CHOSEN_HOST=$(<"$tmpfile")
  echo "$CHOSEN_HOST"
  exit 0
else
  # user pressed Cancel / ESC
  exit 1
fi
