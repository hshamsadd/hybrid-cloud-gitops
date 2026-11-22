resource "vault_policy" "kubernetes_tailscale_operator" {
  name   = "kubernetes-tailscale-operator"
  policy = file("${path.module}/policies/kubernetes-tailscale-operator.hcl")
}

resource "vault_kubernetes_auth_backend_role" "kubernetes_tailscale_operator" {
  backend   = vault_auth_backend.kubernetes.path
  role_name = "kubernetes-tailscale-operator"

  bound_service_account_names = [
    "vault-secrets",
  ]

  bound_service_account_namespaces = [
    "tailscale",
  ]

  token_policies = [
    vault_policy.kubernetes_tailscale_operator.name,
  ]

  audience   = "vault"
  token_ttl  = 600
  token_type = "default"
}
