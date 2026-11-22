variable "vault_addr" {
  type      = string
  sensitive = false
}

variable "kubernetes_host" {
  type      = string
  sensitive = false
}

variable "vault_management_token" {
  type      = string
  sensitive = true
}

variable "kubernetes_ca_cert" {
  type      = string
  sensitive = true
}

variable "kubernetes_reviewer_jwt" {
  type      = string
  sensitive = true
}