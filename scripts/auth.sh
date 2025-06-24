#!/usr/bin/env bash
# shellcheck disable=SC1091

: '
auth.sh – Janus bastion authentication helper

• Prompts for username / password with dialog
• Verifies bcrypt hash from janus_db.users
• Writes the authenticated login into /tmp/janus_user (chmod 600)
'

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/utils.sh"
load_config                    # sets DB_HOST / DB_USER / ...

BACKTITLE='Janus Bastion • Login'

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# ── Prompt with dialog ─────────────────────────────────────────
dialog --backtitle "$BACKTITLE" \
       --mixedform "Credentials" 10 50 0 \
       "Username:" 1 1 ""  1 12 30 0 0 \
       "Password:" 2 1 ""  2 12 30 0 1 2> "$tmp"

USER_LOGIN=$(sed -n 1p "$tmp")
USER_PWD=$(sed -n 2p "$tmp")

# ── Retrieve bcrypt hash from MySQL ────────────────────────────
HASH=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASS" \
             --silent --skip-column-names "$DB_NAME" \
             -e "SELECT password FROM users WHERE username='${USER_LOGIN}'")

# ── Verify password directly (avoids SC2181) ──────────────────
if php -r "exit(password_verify('${USER_PWD}', '${HASH}') ? 0 : 1);"; then
  :  # success, continue
else
  dialog --msgbox "Invalid credentials" 6 30
  exit 1
fi

# ── Safe write of /tmp/janus_user ──────────────────────────────
TMP_FILE="/tmp/janus_user"
rm -f "$TMP_FILE"            2>/dev/null || true   # remove stale root-owned file
printf '%s\n' "$USER_LOGIN" > "$TMP_FILE"
chmod 600 "$TMP_FILE"
chown "$(id -u)":"$(id -g)" "$TMP_FILE"

dialog --msgbox "Welcome ${USER_LOGIN}" 6 30
exit 0
