path "kv/data/kubernetes/production/redis-cache-credentials" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/production/redis-cache-credentials" {
  capabilities = ["read", "list"]
}