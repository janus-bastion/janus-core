#!/usr/bin/env bash
# Stores the private key for host_210 in janus_db.credentials
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/utils.sh"
load_config

HOSTNAME="host_210"
HOST_IP="172.16.0.210"
SSH_PORT=22
JANUS_USER="${JANUS_USER:-janusadmin}"   # default if run manually
KEY_PATH="/opt/janus/keys/host_210/id_rsa"

[[ -f "$KEY_PATH" ]] || { echo "Missing $KEY_PATH" >&2; exit 1; }
BASE64_KEY=$(base64 -w 0 "$KEY_PATH")

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASS" "$DB_NAME" <<SQL
START TRANSACTION;
INSERT IGNORE INTO hosts (hostname, ip_addr, description)
VALUES ('${HOSTNAME}', INET_ATON('${HOST_IP}'), 'Local VM 210');

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
