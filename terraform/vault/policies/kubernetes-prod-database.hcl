path "kv/data/kubernetes/production/cnpg-bootstrap-credentials" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/production/cnpg-bootstrap-credentials" {
  capabilities = ["read", "list"]
}

path "kv/data/kubernetes/production/wallabag" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/production/wallabag" {
  capabilities = ["read", "list"]
}

path "kv/data/kubernetes/production/cnpg-rustfs-backup-credentials" {
  capabilities = ["read"]
}

path "kv/metadata/kubernetes/production/cnpg-rustfs-backup-credentials" {
  capabilities = ["read", "list"]
}