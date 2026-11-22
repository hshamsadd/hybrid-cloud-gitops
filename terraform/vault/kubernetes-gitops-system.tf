resource "vault_kubernetes_auth_backend_role" "kubernetes_gitops_system" {
  backend   = vault_auth_backend.kubernetes.path
  role_name = "kubernetes-gitops-system"

  bound_service_account_names = [
    "vault-secrets",
  ]

  bound_service_account_namespaces = [
    "argocd",
    "gitops-system",
  ]

  token_policies = [
    vault_policy.kubernetes_gitops_system_secrets.name,
  ]

  audience   = "vault"
  token_ttl  = 3600
  token_type = "default"
}