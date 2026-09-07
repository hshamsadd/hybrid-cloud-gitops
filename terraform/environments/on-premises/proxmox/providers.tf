provider "proxmox" {

  # API Authentication
  endpoint = var.proxmox_api_url
  username = "${var.proxmox_user}@pam"
  password = var.proxmox_password
  insecure = true
  ssh {
    agent    = false
    username = var.proxmox_user
    password = var.proxmox_password
    node {
      name    = "proxmox-01"
      address = var.proxmox_address
    }
  }
}

# provider "proxmox" {
#   endpoint  = var.proxmox_api_url
#   api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
#   insecure  = true
#   ssh {
#     agent    = false
#     username = var.proxmox_user 
#     password = var.proxmox_password
#     node {
#       name    = "proxmox-01"
#       address = var.proxmox_address
#     }
#   }
# }