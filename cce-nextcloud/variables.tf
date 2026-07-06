# Common variables (reused from ecs-docker)
variable "domain_name" {
  description = "OTC domain name"
  type        = string
}

variable "project_name" {
  description = "OTC project name"
  type        = string
}

variable "access_key" {
  description = "OTC access key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "OTC secret key"
  type        = string
  sensitive   = true
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

# CCE Cluster variables
variable "cce_cluster_flavor" {
  description = "CCE cluster flavor (control plane)"
  type        = string
  default     = "cce.s2.small" # 2 vCPUs, 4GB RAM
}

variable "cce_cluster_name" {
  description = "Name for the CCE cluster"
  type        = string
  default     = "fusionict-nc-poc-cce"
}

# Node Pool variables
variable "node_pool_name" {
  description = "Name for the node pool"
  type        = string
  default     = "fusionict-nc-poc-np"
}

variable "node_flavor" {
  description = "Flavor for worker nodes"
  type        = string
  default     = "s9.large.2"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 1
}


variable "node_os" {
  description = "Operating system for nodes"
  type        = string
  default     = "Ubuntu 20.04"
}


variable "node_root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 100
}

variable "node_root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "SAS"
}

variable "node_data_volume_size" {
  description = "Data volume size in GB"
  type        = number
  default     = 100
}

variable "node_data_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "SAS"
}

# Network variables
variable "cce_vpc_cidr" {
  description = "CIDR block for the CCE VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "cce_subnet_cidr" {
  description = "CIDR for the CCE Subnet"
  type        = string
  default     = "192.168.100.0/24"
}

# SSH Access
variable "ssh_public_key" {
  description = "Public SSH key for node access"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Nextcloud database password"
  type        = string
  sensitive   = true
}

variable "nextcloud_version" {
  description = "Nextcloud version docker image"
  type        = string
}

variable "mariadb_version" {
  description = "Nextcloud version docker image"
  type        = string
}