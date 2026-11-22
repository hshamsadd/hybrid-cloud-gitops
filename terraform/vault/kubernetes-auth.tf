resource "vault_policy" "kubernetes_gitops_system_secrets" {
  name   = "kubernetes-gitops-system-secrets"
  policy = file("${path.module}/policies/kubernetes-gitops-system-secrets.hcl")
}

resource "vault_auth_backend" "kubernetes" {
  path        = "kubernetes"
  type        = "kubernetes"
  description = "Kubernetes authentication for the kubeadm cluster"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend = vault_auth_backend.kubernetes.path

  kubernetes_host    = var.kubernetes_host
  kubernetes_ca_cert = var.kubernetes_ca_cert

  token_reviewer_jwt_wo         = var.kubernetes_reviewer_jwt
  token_reviewer_jwt_wo_version = 1

  disable_iss_validation = true
}