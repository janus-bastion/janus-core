#!/usr/bin/env bash
# shellcheck disable=SC1091

: '
auth.sh – original version

• Prompts for username / password with dialog
• Verifies bcrypt hash in janus_db.users
• Saves the login name in /tmp/janus_user (chmod 600)
'

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/utils.sh"
load_config           # sets DB_HOST / DB_USER / ...

BACKTITLE='Janus Bastion • Login'

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# ── Dialog prompt ──────────────────────────────────────────────
dialog --backtitle "$BACKTITLE" \
       --mixedform "Credentials" 10 50 0 \
       "Username:" 1 1 ""  1 12 30 0 0 \
       "Password:" 2 1 ""  2 12 30 0 1 2> "$tmp"

USER_LOGIN=$(sed -n 1p "$tmp")
USER_PWD=$(sed -n 2p "$tmp")

# ── Check password hash ───────────────────────────────────────
HASH=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASS" \
             --silent --skip-column-names "$DB_NAME" \
             -e "SELECT password FROM users WHERE username='${USER_LOGIN}'")

php -r "exit(password_verify('${USER_PWD}', '${HASH}') ? 0 : 1);"
[[ $? -eq 0 ]] || { dialog --msgbox "Invalid credentials" 6 30; exit 1; }

# ── Write /tmp/janus_user ─────────────────────────────────────
printf '%s\n' "$USER_LOGIN" > /tmp/janus_user
chmod 600 /tmp/janus_user
chown "$(id -u)":"$(id -g)" /tmp/janus_user

dialog --msgbox "Welcome ${USER_LOGIN}" 6 30
exit 0
