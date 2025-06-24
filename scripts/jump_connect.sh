#!/usr/bin/env bash
# Usage: jump_connect.sh <hostname>
set -euo pipefail

HOSTNAME="$1"
HOST_IP="192.168.79.196"         # updated VM IP
REMOTE_USER="janusadmin"
KEY_FILE="/opt/janus/keys/host_210/id_rsa"

[[ -f "$KEY_FILE" ]] || { echo "SSH key $KEY_FILE not found" >&2; exit 1; }
chmod 600 "$KEY_FILE" 2>/dev/null || true   # ignore if read-only mount

echo "Connecting to ${REMOTE_USER}@${HOST_IP} ..."
exec ssh -i "$KEY_FILE" \
         -o IdentitiesOnly=yes \
         -o StrictHostKeyChecking=accept-new \
         -o LogLevel=ERROR \
         "${REMOTE_USER}@${HOST_IP}"
