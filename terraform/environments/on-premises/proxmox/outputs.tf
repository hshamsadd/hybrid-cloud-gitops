output "vm_user" {
  description = "SSH user for the Proxmox VMs"
  value       = "ubuntu"
}

output "node_ips" {
  description = "Map of node names to their static IP addresses"
  value = {
    for k, v in local.k8s_nodes : k => v.ip
  }
}

output "node_names" {
  description = "Map of internal keys to their actual Proxmox VM names"
  value = {
    for k, v in local.k8s_nodes : k => "k8s-${k}"
  }
}