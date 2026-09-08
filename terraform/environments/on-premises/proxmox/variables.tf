variable "proxmox_api_url" {
  type        = string
  description = "The Proxmox API endpoint URL"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "The Proxmox API token identifier"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "The Proxmox API token UUID secret key"
  sensitive   = true
}

variable "ssh_ca_public_key" {
  type        = string
  description = "Vault SSH user CA public key trusted by the VM."
}

variable "proxmox_user" {
  type        = string
  description = "The Proxmox user for SSH access"
  sensitive = true
}

variable "proxmox_password" {
  type        = string
  description = "The Proxmox root password for SSH access"
  sensitive   = true
}

variable "proxmox_address" {
type        = string
description = "The Proxmox node address for SSH access"
sensitive = true
}