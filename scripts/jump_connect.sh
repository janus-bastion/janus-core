#!/usr/bin/env bash
# Usage: jump_connect.sh <hostname>
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/utils.sh"
load_config

[[ $# -eq 1 ]] || { echo "Usage: $0 <hostname>" >&2; exit 1; }
HOSTNAME="$1"
JANUS_USER=$(cat /tmp/janus_user)

# Helper to run MySQL quickly
q() { mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASS" \
            --silent --skip-column-names "$DB_NAME" -e "$1"; }

HOST_IP=$(q "SELECT INET_NTOA(ip_addr) FROM hosts WHERE hostname='${HOSTNAME}'")
SERVICE_ID=$(q "SELECT s.id FROM services s JOIN hosts h ON h.id=s.host_id
                WHERE h.hostname='${HOSTNAME}' AND s.proto='SSH' AND s.port=22")
USER_ID=$(q "SELECT id FROM users WHERE username='${JANUS_USER}'")
B64_KEY=$(q "SELECT TO_BASE64(secret_enc) FROM credentials
             WHERE user_id=${USER_ID} AND service_id=${SERVICE_ID}
               AND cred_type='SSH_KEY' LIMIT 1")

[[ -n "$B64_KEY" ]] || { echo "No SSH key found for ${HOSTNAME}" >&2; exit 1; }

KEY_FILE=$(mktemp)
trap 'rm -f "$KEY_FILE"' EXIT
echo "$B64_KEY" | base64 -d > "$KEY_FILE"
chmod 600 "$KEY_FILE"

echo "Connecting to ${HOSTNAME} (${HOST_IP}) ..."
ssh -J "${JANUS_USER}@127.0.0.1" -i "$KEY_FILE" \
    -o LogLevel=ERROR "${JANUS_USER}@${HOST_IP}"
