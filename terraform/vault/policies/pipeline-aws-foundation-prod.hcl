path "kv/data/platforms/hcp-terraform/ci" {
  capabilities = ["read"]
}

path "kv/data/platforms/tailscale/provisioner" {
  capabilities = ["read"]
}

# The Legacy Role (Keeps existing GitHub pipelines working)
path "ssh-client-signer/sign/homelab-ci" {
  capabilities = ["update"]
}

# The New Enterprise Role (For GitLab and future migration)
path "ssh-client-signer/sign/platform-operator" {
  capabilities = ["update"]
}