#!/usr/bin/env bash
# Usage: jump_connect.sh <hostname>
set -euo pipefail

HOSTNAME="$1"
HOST_IP="192.168.79.196"         # fixed IP
REMOTE_USER="janusadmin"         # same user on bastion and VM
SOURCE_KEY="/opt/janus/keys/host_210/id_rsa"

[[ -f "$SOURCE_KEY" ]] || { echo "Key $SOURCE_KEY not found" >&2; exit 1; }

# copy to a writeable location and secure permissions
KEY_FILE=$(mktemp)
trap 'rm -f "$KEY_FILE"' EXIT
cp "$SOURCE_KEY" "$KEY_FILE"
chmod 600 "$KEY_FILE"

echo "Connecting to ${REMOTE_USER}@${HOST_IP} via bastion ..."
ssh -J "${REMOTE_USER}@127.0.0.1" \
    -i "$KEY_FILE" \
    -o LogLevel=ERROR \
    "${REMOTE_USER}@${HOST_IP}"
