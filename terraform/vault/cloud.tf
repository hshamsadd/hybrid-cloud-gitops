terraform {
  cloud {
    organization = "zshamsadd-devops"
    workspaces {
      project = "On-Premises"
      name    = "kubernetes"
    }
  }
}