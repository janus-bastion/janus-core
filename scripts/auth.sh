#!/usr/bin/env bash
# shellcheck disable=SC1091

: '
auth.sh – Janus bastion authentication helper

• Prompts for user / password (or uses env vars in headless mode)
• Verifies the bcrypt hash in janus_db.users
• Stores the authenticated username in /tmp/janus_user
  (world-unreadable, owned by the logged-in user)
'

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/utils.sh"
load_config

# ── Prompt (stripped for brevity – keep your existing dialog / headless code) ──
read -rp "Janus username: " USER_LOGIN
read -rsp "Password: "      USER_PWD; echo

# ── Check hash in MySQL (unchanged) ───────────────────────────────────────────
HASH=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASS" \
            --silent --skip-column-names "$DB_NAME" \
            -e "SELECT password FROM users WHERE username='${USER_LOGIN}'")
php -r "exit(password_verify('${USER_PWD}', '${HASH}') ? 0 : 1);"
AUTH_OK=$?

if [[ $AUTH_OK -ne 0 ]]; then
  echo "Invalid credentials."
  exit 1
fi

# ── Safe write of /tmp/janus_user ─────────────────────────────────────────────
TMP_FILE="/tmp/janus_user"

# Remove if it exists and we cannot overwrite
if [[ -e "$TMP_FILE" && ! -w "$TMP_FILE" ]]; then
  rm -f "$TMP_FILE"
fi

printf '%s\n' "$USER_LOGIN" > "$TMP_FILE"
chmod 600 "$TMP_FILE"
chown "$(id -u)":"$(id -g)" "$TMP_FILE"

echo "Authenticated as $USER_LOGIN"
exit 0
