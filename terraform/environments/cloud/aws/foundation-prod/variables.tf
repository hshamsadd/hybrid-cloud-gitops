variable "vm_name" {
  type        = string
  description = "Name of the virtual machine."
  default     = "cloud-node-05"
}

variable "vm_user" {
  type        = string
  description = "Linux user used for SSH and Ansible."
  default     = "ubuntu"
}

variable "ssh_ca_public_key" {
  type        = string
  description = "Vault SSH user CA public key trusted by the VM."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.24.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for the subnet."
  default     = "10.24.11.0/24"
}

variable "instance_type" {
  type        = string
  description = "Type of the EC2 instance."
  default     = "t3.micro"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the infrastructure."
  default     = "eu-central-1"
}

variable "k3s_node_name" {
  type        = string
  description = "Node name registered with K3s."
  default     = "worker-05"
}