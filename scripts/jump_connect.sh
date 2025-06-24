#!/usr/bin/env bash
# Usage: jump_connect.sh <hostname>
set -euo pipefail

HOSTNAME="$1"
HOST_IP="192.168.79.196"          # fixed IP (update if it changes again)
REMOTE_USER="janusadmin"          # same user on bastion and VM
KEY_FILE="/opt/janus/keys/host_210/id_rsa"

[[ -f "$KEY_FILE" ]] || { echo "SSH key $KEY_FILE not found" >&2; exit 1; }
chmod 600 "$KEY_FILE"

echo "Connecting to ${REMOTE_USER}@${HOST_IP} via bastion ..."
ssh -J "${REMOTE_USER}@127.0.0.1" \
    -i "$KEY_FILE" \
    -o LogLevel=ERROR \
    "${REMOTE_USER}@${HOST_IP}"
