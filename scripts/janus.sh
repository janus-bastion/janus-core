#!/usr/bin/env bash

SESSION_TOKEN=$(auth.sh) || { echo "Authentication failed"; exit 1; }

export JANUS_SESSION="$SESSION_TOKEN"
echo "Session token: $JANUS_SESSION"
