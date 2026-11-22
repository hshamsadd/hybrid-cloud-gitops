path "kv/data/kubernetes/production/rustfs-admin-credentials" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/production/rustfs-admin-credentials" {
  capabilities = ["read", "list"]
}