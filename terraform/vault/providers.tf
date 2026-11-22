provider "vault" {
  address = var.vault_addr
  token   = var.vault_management_token
}