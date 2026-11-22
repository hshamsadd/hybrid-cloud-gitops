path "kv/data/kubernetes/production/wallabag" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/production/wallabag" {
  capabilities = ["read", "list"]
}

path "kv/data/kubernetes/production/redis-cache-credentials" {
  capabilities = ["read"]
}