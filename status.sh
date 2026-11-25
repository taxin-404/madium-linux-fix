#!/bin/sh
# Quick reachability check for the pieces Madium needs.

HOST=auth.getmadium.xyz
CDN=165.245.199.89

echo "== DNS for $HOST"
getent ahostsv4 "$HOST" | head -1 || echo "  does not resolve"

echo "== auth API"
curl -s -m 10 -o /dev/null -w '  %{url_effective} -> %{http_code}\n' \
    "https://$HOST/api/v1/users/authenticated" || echo "  unreachable"

echo "== content origin manifest"
curl -s -m 15 "https://$CDN/manifest.json" \
    | sed -n '1,6p' || echo "  unreachable"
