#!/usr/bin/env bash

set -euo pipefail

REMOTE_IP="172.16.0.210"
REMOTE_PORT=22
REMOTE_USER="janus"
KEY_DIR="$(dirname "$0")/../keys/host_210"
KEY_FILE="${KEY_DIR}/id_rsa"

mkdir -p "$KEY_DIR"
if [[ ! -f "$KEY_FILE" ]]; then
  echo "Generating SSH key ${KEY_FILE} ..."
  ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N "" -q
else
  echo "Using existing key ${KEY_FILE}"
fi

echo "Installing public key on ${REMOTE_USER}@${REMOTE_IP} ..."
ssh-copy-id -i "${KEY_FILE}.pub" "-p${REMOTE_PORT}" "${REMOTE_USER}@${REMOTE_IP}"

echo "Key installed. Mount ./keys into janus-core when you run Docker."
