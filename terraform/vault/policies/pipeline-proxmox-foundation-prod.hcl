path "kv/data/platforms/hcp-terraform/ci" {
  capabilities = ["read"]
}

path "kv/data/platforms/tailscale/provisioner" {
  capabilities = ["read"]
}

path "kv/data/platforms/proxmox/ci" {
  capabilities = ["read"]
}

path "ssh-client-signer/sign/homelab-ci" {
  capabilities = ["update"]
}

path "ssh-client-signer/sign/platform-operator" {
  capabilities = ["update"]
}