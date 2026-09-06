# 1. Render the YAML template and upload it to Proxmox as a Snippet
resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  # We create one file per node so Terraform tracks them cleanly
  for_each = local.k8s_nodes

  content_type = "snippets"
  datastore_id = "local"
  node_name    = "proxmox-01"

  source_raw {
    data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", 
    {
      ssh_ca_public_key = var.ssh_ca_public_key
    }
    )
    file_name = "user-data-k8s-${each.key}.yaml"
  }
}

# 2. Clone the Kubernetes VMs from template 9000
resource "proxmox_virtual_environment_vm" "k8s_cluster" {
  for_each = local.k8s_nodes

  name      = "k8s-${each.key}"
  node_name = "proxmox-01"

  # Matches: template: 1 (using VM 9000)
  clone {
    vm_id = 9000
  }

  # Matches: agent: 1
  agent {
    enabled = true
  }

  # Matches: cpu: host, cores: 2
  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  # Matches: memory: 2048
  memory {
    dedicated = each.value.ram
  }

  # Matches: scsihw: virtio-scsi-single
  scsi_hardware = "virtio-scsi-single"

  # Note: disk settings (size, discard, iothread) are inherited from the clone,
  # but you can override them here if you want to expand the disk later.
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 30
    # You do not need discard or iothread here if they are already on the template, 
    # but defining them ensures Terraform enforces it.
    discard  = "on"
    iothread = true
  }

  # Matches: net0: bridge=vmbr1
  network_device {
    bridge = "vmbr1"
  }

  # Matches: ide2: cloudinit
  initialization {
    # Link the uploaded Snippet from Step 1
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data[each.key].id

    # IP injection stays natively in HCL so you can loop through local.k8s_nodes
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = each.value.gw
      }
    }
  }
}