# =============================================
# Outputs for CCE Cluster Deployment
# =============================================

# ------------------------
# Cluster Information
# ------------------------

output "cluster_name" {
  value       = opentelekomcloud_cce_cluster_v3.cce_cluster.name
  description = "Name of the CCE cluster"
}

output "cluster_id" {
  value       = opentelekomcloud_cce_cluster_v3.cce_cluster.id
  description = "ID of the CCE cluster"
}

# ------------------------
# Node Pool Information
# ------------------------

output "node_pool_name" {
  value       = opentelekomcloud_cce_node_pool_v3.node_pool.name
  description = "Name of the node pool"
}

output "node_pool_id" {
  value       = opentelekomcloud_cce_node_pool_v3.node_pool.id
  description = "ID of the node pool"
}

output "node_count" {
  value       = opentelekomcloud_cce_node_pool_v3.node_pool.initial_node_count
  description = "Number of nodes in the node pool"
}

# ------------------------
# Network Information
# ------------------------

output "vpc_id" {
  value       = opentelekomcloud_vpc_v1.cce_vpc.id
  description = "VPC ID"
}

output "subnet_id" {
  value       = opentelekomcloud_vpc_subnet_v1.cce_subnet.id
  description = "Subnet ID"
}

output "security_group_id" {
  value       = opentelekomcloud_networking_secgroup_v2.cce_secgroup.id
  description = "ID of the security group"
}

# ------------------------
# Access Information
# ------------------------

output "keypair_name" {
  value       = opentelekomcloud_compute_keypair_v2.cce_keypair.name
  description = "Name of the SSH keypair"
}

# Note: Cluster endpoint and kubeconfig will be available after cluster creation
# You can get them using:
# terraform output cluster_id
# Then use: openstack container cluster show <cluster_id> to get endpoint
