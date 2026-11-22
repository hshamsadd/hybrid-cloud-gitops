path "kv/data/platforms/tailscale/provisioner" {
  capabilities = ["read"]
}

path "ssh-client-signer/sign/homelab-ci" {
  capabilities = ["update"]
}

path "ssh-client-signer/sign/platform-operator" {
  capabilities = ["update"]
}