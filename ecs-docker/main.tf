# ------------------------
# Image Reference
# ------------------------

 data "opentelekomcloud_images_image_v2" "vm_image" {
   name        = var.nc_vm_image
   most_recent = true
}

# ------------------------
# Naming logic
# ------------------------

locals {
  prefix = var.resource_prefix
  app    = "nc"
  env    = "poc"

  # Extract nl / de from eu-nl / eu-de
  region_short = split("-", var.region)[1]

  name_base = "${local.prefix}-${local.app}-${local.env}-${local.region_short}"

  # Calculate gateway IP (first usable IP in subnet)
  subnet_gateway = cidrhost(var.nc_subnet_cidr, 1)
}

# ------------------------
# Networking
# ------------------------

# Create a VPC
resource "opentelekomcloud_vpc_v1" "vpc" {
   name = "${local.name_base}-vpc"
   cidr = var.nc_vpc_cidr
}

# Create a VPC Subnet
resource "opentelekomcloud_vpc_subnet_v1" "subnet" {
  name       = "${local.name_base}-subnet"
  vpc_id     = opentelekomcloud_vpc_v1.vpc.id
  cidr       = var.nc_subnet_cidr
  gateway_ip = local.subnet_gateway
}

# Create a Security Group
resource "opentelekomcloud_networking_secgroup_v2" "secgroup" {
  name        = "${local.name_base}-secgroup"
  description = "Security group for Nextcloud POC"
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "secgroup_rule_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.secgroup.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "secgroup_rule_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.secgroup.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "secgroup_rule_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.secgroup.id
}

# ------------------------
# Compute
# ------------------------

# Create an SSH key pair
resource "opentelekomcloud_compute_keypair_v2" "keypair" {
  name       = "${local.name_base}-key"
  public_key = var.nc_ssh_public_key
}

# Create a VM
resource "opentelekomcloud_compute_instance_v2" "vm" {
  name            = "${local.name_base}-vm"
  image_name      = var.nc_vm_image
  flavor_name     = var.nc_vm_flavor
  key_pair        = opentelekomcloud_compute_keypair_v2.keypair.name
  security_groups = [opentelekomcloud_networking_secgroup_v2.secgroup.name]
  user_data       = filebase64("cloud-init.yml")

   network {
     uuid = opentelekomcloud_vpc_subnet_v1.subnet.network_id
   }

  block_device {
    uuid                  = data.opentelekomcloud_images_image_v2.vm_image.id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 40
    boot_index            = 0
    delete_on_termination = true
  }
}

# ------------------------
# Public Networking
# ------------------------

# Create a Floating IP for the VM
resource "opentelekomcloud_networking_floatingip_v2" "fip" {
  pool = "admin_external_net"
}


# Associate Floating IP with the VM instance
resource "opentelekomcloud_compute_floatingip_associate_v2" "fip_assoc" {
  floating_ip = opentelekomcloud_networking_floatingip_v2.fip.address
  instance_id = opentelekomcloud_compute_instance_v2.vm.id
}

output "public_ip" {
  value       = "The nextcloud URI: https://${opentelekomcloud_networking_floatingip_v2.fip.address}:8080"
  description = "Public IP Nextcloud VM"
}

output "notice" {
  value       = "Login using ubuntu user and key authentication or use ECS console to get pass for ubuntu user. Do change password!!"
  description = "NOTICE"
}