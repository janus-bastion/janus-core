#!/usr/bin/env bash

: '
auth.sh - TUI / headless login using dialog

- prompts for username/password using dialog
- verifies clear-text password against the bcrypt hash stored in the
  'users' table of janus_db.
- generates a UUID v4 session token in ./.janus_session + prints to stdout
  (so other scripts such as janus.sh can pick it up).
- stub mode: set AUTH_STUB=1 to bypass database verification (handy for CI).
- headless mode: set DIALOG=cmdline and provide USER_LOGIN / USER_PWD env
  vars - useful in CI or plain SSH sessions without a TTY.
'

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"        # janus-mysql inside Docker network
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-janus_db}"
DB_USER="${DB_USER:-janus}"
DB_PASS="${DB_PASS:-janus}"

DIALOG_BACKTITLE='Janus Bastion - Authentication'
SESSION_FILE="./.janus_session"

for bin in dialog mysql uuidgen php; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "❌ '$bin' is not installed or not in PATH." >&2
    exit 2
  }
done

# generate a random UUID (v4)
gen_token() { uuidgen; }

# check clear‑text password $1 against bcrypt hash $2 using PHP's password_verify
bcrypt_verify() {
  local pwd="$1" hash="$2"
  php -r "echo password_verify('${pwd}', '${hash}') ? '1' : '0';"
}

# credentials collect
if [[ "${DIALOG:-}" == "cmdline" ]]; then
  # Headless mode – expect env vars
  USER_LOGIN="${USER_LOGIN:?USER_LOGIN not set}"
  USER_PWD="${USER_PWD:?USER_PWD not set}"
else
  tmpfile=$(mktemp)
  trap 'rm -f "${tmpfile}"' EXIT

  dialog --backtitle "${DIALOG_BACKTITLE}" \
       --title 'Login required' \
       --mixedform 'Please enter your Janus credentials:' 12 50 0 \
       'Username:'  1 1 '' 1 15 30 0 0 \
       'Password:'  2 1 '' 2 15 30 0 1 2> "${tmpfile}"

  USER_LOGIN=$(sed -n 1p "${tmpfile}")
  USER_PWD=$(sed -n 2p "${tmpfile}")
fi

# auth part
AUTH_OK=0
if [[ "${AUTH_STUB:-0}" == "1" ]]; then
  AUTH_OK=1
else
  HASH_IN_DB=$(mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" \
               --password="${DB_PASS}" --silent --skip-column-names \
               -e "SELECT password FROM users WHERE username='${USER_LOGIN}'" "${DB_NAME}" | tr -d '\r\n')

  if [[ -n "${HASH_IN_DB}" ]]; then
    if [[ "$(bcrypt_verify "${USER_PWD}" "${HASH_IN_DB}")" == "1" ]]; then
      AUTH_OK=1
    fi
  fi
fi

# outcome
if [[ "${AUTH_OK}" == "1" ]]; then
  TOKEN=$(gen_token)
  echo "${TOKEN}" > "${SESSION_FILE}"
  chmod 600 "${SESSION_FILE}"
  if [[ "${DIALOG:-}" != "cmdline" ]]; then
    dialog --msgbox "Authentication successful!\nSession: ${TOKEN}" 8 50
  fi
  echo "${TOKEN}"
  exit 0
else
  if [[ "${DIALOG:-}" != "cmdline" ]]; then
    dialog --msgbox 'Invalid credentials ☹️' 6 40
  fi
  echo 'Invalid credentials' >&2
  exit 1
fi
