#!/bin/sh
# Point auth.getmadium.xyz at a live Cloudflare edge.
# Public DNS for *.getmadium.xyz currently answers the parked wildcard 0.0.0.17.
set -e

HOST=auth.getmadium.xyz
IP="${1:-172.67.209.34}"

if grep -qE "[[:space:]]$HOST$" /etc/hosts; then
    echo "$HOST already pinned in /etc/hosts"
    grep -E "[[:space:]]$HOST$" /etc/hosts
    exit 0
fi

echo "adding: $IP $HOST"
if [ "$(id -u)" -eq 0 ]; then
    printf '%s %s\n' "$IP" "$HOST" >> /etc/hosts
else
    printf '%s %s\n' "$IP" "$HOST" | sudo tee -a /etc/hosts >/dev/null
fi

echo "done. new resolution:"
getent ahostsv4 "$HOST" | head -1
