terraform {
  cloud {
    organization = "zshamsadd-devops"

    workspaces {
      project = "Cloud"
      name    = "proxmox-infra-core"
    }
  }
}