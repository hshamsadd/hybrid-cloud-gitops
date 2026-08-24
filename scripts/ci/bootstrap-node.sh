#!/usr/bin/env bash
set -Eeuo pipefail

cloud-init status --wait

export DEBIAN_FRONTEND=noninteractive

echo "Waiting for apt/dpkg locks to become available..."
for attempt in $(seq 1 60); do
  if ! fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; then
    echo "apt/dpkg locks are available."
    break
  fi
  if [[ "$attempt" -eq 60 ]]; then
    echo "ERROR: apt/dpkg remained locked for too long." >&2
    exit 1
  fi
  echo "apt/dpkg is busy. Waiting 5 seconds..."
  sleep 5
done

apt-get update
apt-get install -y ca-certificates curl

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

if [[ -n "${TAILSCALE_AUTH_KEY_B64:-}" ]]; then
  TS_AUTH_KEY="$(printf '%s' "${TAILSCALE_AUTH_KEY_B64}" | base64 -d)"
  
  # SPLIT IDENTITY: Use TAILSCALE_HOSTNAME (cloud-node-02). Fallback to K3S_NODE_NAME for safety.
  TS_HOSTNAME="${TAILSCALE_HOSTNAME:-${K3S_NODE_NAME:-$(hostname)}}"

  if tailscale status >/dev/null 2>&1; then
    echo "Tailscale is already connected."
  else
    tailscale up --auth-key="${TS_AUTH_KEY}" --hostname="${TS_HOSTNAME}" --accept-dns=true
  fi
else
  echo "ERROR: TAILSCALE_AUTH_KEY_B64 is not set." >&2
  exit 1
fi

if [[ -n "${SSH_CA_B64:-}" ]]; then
  echo "Configuring Vault SSH CA..."
  install -d -m 0755 /etc/ssh/sshd_config.d
  install -d -m 0755 /run/sshd

  printf '%s' "${SSH_CA_B64}" | base64 -d > /etc/ssh/vault-user-ca.pub
  chmod 0644 /etc/ssh/vault-user-ca.pub

  cat > /etc/ssh/sshd_config.d/90-vault-user-ca.conf <<'SSHD_EOF'
TrustedUserCAKeys /etc/ssh/vault-user-ca.pub
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
SSHD_EOF

  /usr/sbin/sshd -t
  systemctl restart ssh
fi


# #!/usr/bin/env bash
# set -Eeuo pipefail

# cloud-init status --wait

# export DEBIAN_FRONTEND=noninteractive

# echo "Waiting for apt/dpkg locks to become available..."
# for attempt in $(seq 1 60); do
#   if ! fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; then
#     echo "apt/dpkg locks are available."
#     break
#   fi

#   if [[ "$attempt" -eq 60 ]]; then
#     echo "ERROR: apt/dpkg remained locked for too long." >&2
#     exit 1
#   fi

#   echo "apt/dpkg is still busy (${attempt}/60). Waiting 5 seconds..."
#   sleep 5
# done

# apt-get update
# apt-get install -y ca-certificates curl

# if ! command -v tailscale >/dev/null 2>&1; then
#   curl -fsSL https://tailscale.com/install.sh | sh
# fi

# if [[ -n "${TAILSCALE_AUTH_KEY_B64:-}" ]]; then
#   TS_AUTH_KEY="$(printf '%s' "${TAILSCALE_AUTH_KEY_B64}" | base64 -d)"
#   if tailscale status >/dev/null 2>&1; then
#     echo "Tailscale is already connected."
#   else
#     tailscale up \
#       --auth-key="${TS_AUTH_KEY}" \
#       --hostname="${K3S_NODE_NAME}" \
#       --accept-dns=true
#   fi
# else
#   echo "ERROR: TAILSCALE_AUTH_KEY_B64 is not set." >&2
#   exit 1
# fi

# if [[ -n "${SSH_CA_B64:-}" ]]; then
#   echo "Configuring Vault SSH CA..."
#   install -d -m 0755 /etc/ssh/sshd_config.d
#   install -d -m 0755 /run/sshd

#   printf '%s' "${SSH_CA_B64}" | base64 -d > /etc/ssh/vault-user-ca.pub
#   chmod 0644 /etc/ssh/vault-user-ca.pub

#   cat > /etc/ssh/sshd_config.d/90-vault-user-ca.conf <<'SSHD_EOF'
# TrustedUserCAKeys /etc/ssh/vault-user-ca.pub
# PasswordAuthentication no
# KbdInteractiveAuthentication no
# PermitRootLogin no
# SSHD_EOF

#   /usr/sbin/sshd -t
#   systemctl restart ssh
# fi



# #!/usr/bin/env bash
# set -Eeuo pipefail

# cloud-init status --wait

# export DEBIAN_FRONTEND=noninteractive

# echo "Waiting for apt/dpkg locks to become available..."
# for attempt in $(seq 1 60); do
#   if ! fuser \
#     /var/lib/dpkg/lock-frontend \
#     /var/lib/dpkg/lock \
#     /var/lib/apt/lists/lock \
#     /var/cache/apt/archives/lock \
#     >/dev/null 2>&1
#   then
#     echo "apt/dpkg locks are available."
#     break
#   fi

#   if [[ "$attempt" -eq 60 ]]; then
#     echo "ERROR: apt/dpkg remained locked for too long." >&2
#     exit 1
#   fi

#   echo "apt/dpkg is still busy (${attempt}/60). Waiting 5 seconds..."
#   sleep 5
# done

# apt-get update
# apt-get install -y ca-certificates curl

# if ! command -v tailscale >/dev/null 2>&1; then
#   curl -fsSL https://tailscale.com/install.sh | sh
# fi

# if [[ -n "${TAILSCALE_AUTH_KEY_B64:-}" ]]; then
#   TS_AUTH_KEY="$(printf '%s' "$TAILSCALE_AUTH_KEY_B64" | base64 -d)"
#   if tailscale status >/dev/null 2>&1; then
#     echo "Tailscale is already connected."
#   else
#     tailscale up \
#       --auth-key="$TS_AUTH_KEY" \
#       --hostname="${K3S_NODE_NAME}" \
#       --accept-dns=true
#   fi
# else
#   echo "ERROR: TAILSCALE_AUTH_KEY_B64 is not set." >&2
#   exit 1
# fi

# if [[ -n "${SSH_CA_B64:-}" ]]; then
#   echo "Configuring Vault SSH CA..."
#   install -d -m 0755 /etc/ssh/sshd_config.d
#   install -d -m 0755 /run/sshd

#   printf '%s' "$SSH_CA_B64" | base64 -d > /etc/ssh/vault-user-ca.pub
#   chmod 0644 /etc/ssh/vault-user-ca.pub

#   cat > /etc/ssh/sshd_config.d/90-vault-user-ca.conf <<'SSHD_EOF'
# TrustedUserCAKeys /etc/ssh/vault-user-ca.pub
# PasswordAuthentication no
# KbdInteractiveAuthentication no
# PermitRootLogin no
# SSHD_EOF

#   /usr/sbin/sshd -t
#   systemctl restart ssh
# fi