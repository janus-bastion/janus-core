#!/usr/bin/env bash
# Usage: jump_connect.sh <hostname>
set -euo pipefail

# ── Static host data (adapt if the IP changes again) ─────────────
HOSTNAME="$1"
HOST_IP="192.168.79.196"
REMOTE_USER="janusadmin"
SOURCE_KEY="/opt/janus/keys/host_210/id_rsa"   # read-only volume

[[ -f "$SOURCE_KEY" ]] || { echo "Key $SOURCE_KEY not found" >&2; exit 1; }

# ── Copy to a temp file with strict perms ────────────────────────
KEY_FILE=$(mktemp)
trap 'rm -f "$KEY_FILE"' EXIT
cp "$SOURCE_KEY" "$KEY_FILE"
chmod 600 "$KEY_FILE"

echo "Connecting to ${REMOTE_USER}@${HOST_IP} ..."
exec ssh -i "$KEY_FILE" \
         -o IdentitiesOnly=yes \
         -o StrictHostKeyChecking=accept-new \
         -o LogLevel=ERROR \
         "${REMOTE_USER}@${HOST_IP}"
