#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/utils.sh"
load_config

HOSTNAME="host_210"
HOST_IP="192.168.79.196"   # ← NEW IP
SSH_PORT=22

if [[ -z "${JANUS_USER:-}" && -f /tmp/janus_user ]]; then
  JANUS_USER=$(< /tmp/janus_user)
fi
JANUS_USER="${JANUS_USER:-janusadmin}"

KEY_PATH="/opt/janus/keys/host_210/id_rsa"
[[ -f "$KEY_PATH" ]] || { echo "Missing key $KEY_PATH" >&2; exit 1; }
BASE64_KEY=$(base64 < "$KEY_PATH" | tr -d '\n')

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASS" "$DB_NAME" <<SQL
START TRANSACTION;
INSERT INTO hosts (hostname, ip_addr, description)
VALUES ('${HOSTNAME}', INET_ATON('${HOST_IP}'), 'Local VM 210')
ON DUPLICATE KEY UPDATE ip_addr = VALUES(ip_addr);

INSERT IGNORE INTO services (host_id, proto, port)
VALUES ( (SELECT id FROM hosts WHERE hostname='${HOSTNAME}'), 'SSH', ${SSH_PORT});

REPLACE INTO credentials (user_id, service_id, cred_type, secret_enc, valid_from)
VALUES (
  (SELECT id FROM users WHERE username='${JANUS_USER}'),
  (SELECT id FROM services WHERE host_id=(SELECT id FROM hosts WHERE hostname='${HOSTNAME}')
         AND proto='SSH' AND port=${SSH_PORT}),
  'SSH_KEY',
  FROM_BASE64('${BASE64_KEY}'),
  NOW()
);
COMMIT;
SQL

echo "Credential stored for ${JANUS_USER}@${HOSTNAME}."
