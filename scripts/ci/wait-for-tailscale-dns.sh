#!/usr/bin/env bash
set -euo pipefail

TARGET_HOST="${1:-}"

if [[ -z "$TARGET_HOST" ]]; then
  echo "Usage: $0 <hostname>" >&2
  exit 1
fi

echo "Waiting for Tailscale MagicDNS resolution for $TARGET_HOST..." >&2

VM_IP=""
for attempt in $(seq 1 60); do
  VM_IP="$(getent ahostsv4 "$TARGET_HOST" 2>/dev/null | awk 'NR == 1 { print $1 }' || true)"
  if [[ -n "$VM_IP" ]]; then
    echo "Resolved ${TARGET_HOST} to ${VM_IP}." >&2
    break
  fi
  sleep 5
done

if [[ -z "$VM_IP" ]]; then
  echo "ERROR: Could not resolve $TARGET_HOST." >&2
  exit 1
fi

tailscale ping --until-direct=false -c 3 "$TARGET_HOST" >&2

# Return only the IP address to stdout so GitHub Actions can capture it
printf "%s" "$VM_IP"
