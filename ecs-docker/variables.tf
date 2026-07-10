variable "domain_name" {}
variable "tenant_name" {}
variable "access_key" {
  sensitive = true
}
variable "secret_key" {
  sensitive = true
}

variable "region" {
  description = "Allowed regions: eu-nl or eu-de"
  validation {
    condition = (
      contains(["eu-nl", "eu-de"], var.region) &&
      length(split("-", var.region)) == 2
    )
    error_message = "Region must be in format 'eu-nl' or 'eu-de'."
  }
}

variable "resource_prefix" {}

variable "nc_vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "nc_subnet_cidr" {
  description = "CIDR for the Subnet"
  type        = string
  default     = "192.168.100.0/24"
}

variable "nc_vm_image" {
  description = "Image for the VM (Ubuntu 24.04)"
  type        = string
  default     = "Standard_Ubuntu_24.04_amd64_uefi_latest"
}

variable "nc_vm_flavor" {
  description = "Flavor for the VM"
  type        = string
  default     = "s3.large.2" # 2 vCPUs, 4GB RAM
}

variable "nc_ssh_public_key" {
  description = "Public SSH key for VM access"
  type        = string
  sensitive   = true
}