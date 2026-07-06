# =============================================
# CCE Cluster Deployment for Nextcloud POC
# OpenTelekomCloud T-Cloud
# Solution: Create VPC/Subnet first, then CCE cluster with explicit dependencies
# =============================================

# ------------------------
# Data Sources
# ------------------------

data "opentelekomcloud_identity_project_v3" "project" {
  name = var.project_name
}

# ------------------------
# Naming logic
# ------------------------

locals {
  prefix         = "fusionict"
  app            = "nc"
  env            = "poc"
  region_short   = split("-", var.region)[1]
  name_base      = "${local.prefix}-${local.app}-${local.env}-${local.region_short}"
  subnet_gateway = cidrhost(var.cce_subnet_cidr, 1)
}

# =============================================
# STEP 1: VPC and Networking
# =============================================

resource "opentelekomcloud_vpc_v1" "cce_vpc" {
  name = "${local.name_base}-cce-vpc"
  cidr = var.cce_vpc_cidr
}

resource "opentelekomcloud_vpc_subnet_v1" "cce_subnet" {
  name       = "${local.name_base}-cce-subnet"
  vpc_id     = opentelekomcloud_vpc_v1.cce_vpc.id
  cidr       = var.cce_subnet_cidr
  gateway_ip = local.subnet_gateway
  dns_list   = ["100.125.4.25", "100.125.129.199"]
}

# =============================================
# INTERNET ACCESS
# =============================================

# Add this new resource:
resource "opentelekomcloud_networking_floatingip_v2" "nat_fip" {
  pool = "admin_external_net"
}


resource "opentelekomcloud_nat_gateway_v2" "cce_nat" {
  name                = "${local.name_base}-nat"
  description         = "NAT Gateway for CCE internet access"
  spec                = "0"
  internal_network_id = opentelekomcloud_vpc_subnet_v1.cce_subnet.id
  router_id           = opentelekomcloud_vpc_v1.cce_vpc.id
}

resource "opentelekomcloud_nat_snat_rule_v2" "cce_snat" {
  nat_gateway_id = opentelekomcloud_nat_gateway_v2.cce_nat.id
  network_id     = opentelekomcloud_vpc_subnet_v1.cce_subnet.id
  floating_ip_id = opentelekomcloud_networking_floatingip_v2.nat_fip.id
  source_type    = "0" # 0 = all instances in the VPC
}

# =============================================
# STEP 2: Security Group for CCE
# =============================================

resource "opentelekomcloud_networking_secgroup_v2" "cce_secgroup" {
  name        = "${local.name_base}-cce-secgroup"
  description = "Security group for CCE cluster and nodes"
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "cce_rule_all" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_group_id   = opentelekomcloud_networking_secgroup_v2.cce_secgroup.id
  security_group_id = opentelekomcloud_networking_secgroup_v2.cce_secgroup.id
}

# resource "opentelekomcloud_networking_secgroup_rule_v2" "nextcloud_nodeport" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 30000  # NodePort range start
#   port_range_max    = 32767  # NodePort range end
#   remote_ip_prefix  = "0.0.0.0/0"  # Allow from anywhere
#   security_group_id = opentelekomcloud_networking_secgroup_v2.cce_secgroup.id
# }

# =============================================
# STEP 3: SSH Key Pair for Node Access (REQUIRED)
# =============================================

resource "opentelekomcloud_compute_keypair_v2" "cce_keypair" {
  name       = "${local.name_base}-cce-key"
  public_key = var.ssh_public_key
}

resource "opentelekomcloud_networking_floatingip_v2" "cce_cluster_fip" {
  pool = "admin_external_net" # or your external network name
}

# =============================================
# STEP 4: CCE Cluster
# =============================================

resource "opentelekomcloud_cce_cluster_v3" "cce_cluster" {
  name                   = var.cce_cluster_name
  description            = "Nextcloud POC Cluster"
  cluster_type           = "VirtualMachine"
  flavor_id              = var.cce_cluster_flavor
  vpc_id                 = opentelekomcloud_vpc_v1.cce_vpc.id
  subnet_id              = opentelekomcloud_vpc_subnet_v1.cce_subnet.id
  container_network_type = "vpc-router"
  kube_proxy_mode        = "iptables"
  authentication_mode    = "rbac"
  timezone               = "Europe/Madrid"
  eip                    = opentelekomcloud_networking_floatingip_v2.cce_cluster_fip.address

  depends_on = [
    opentelekomcloud_identity_agency_v3.cce_swr_access,
    opentelekomcloud_nat_snat_rule_v2.cce_snat
  ]
}

# =============================================
# STEP 5: Node Pool
# =============================================

resource "opentelekomcloud_cce_node_pool_v3" "node_pool" {
  name               = var.node_pool_name
  cluster_id         = opentelekomcloud_cce_cluster_v3.cce_cluster.id
  flavor             = var.node_flavor
  os                 = var.node_os
  initial_node_count = var.node_count
  max_node_count     = var.node_max_count
  availability_zone  = "${var.region}-02"
  subnet_id          = opentelekomcloud_vpc_subnet_v1.cce_subnet.id
  key_pair           = opentelekomcloud_compute_keypair_v2.cce_keypair.name

  root_volume {
    volumetype = var.node_root_volume_type
    size       = var.node_root_volume_size
  }

  data_volumes {
    volumetype = var.node_data_volume_type
    size       = var.node_data_volume_size
  }

  depends_on = [opentelekomcloud_identity_agency_v3.cce_swr_access]
}

# =============================================
# STEP 6: Kubernetes / HELM Provider for CCE
# =============================================

provider "kubernetes" {
  alias                  = "cce"
  host                   = opentelekomcloud_cce_cluster_v3.cce_cluster.external
  cluster_ca_certificate = base64decode(opentelekomcloud_cce_cluster_v3.cce_cluster.certificate_clusters[0].certificate_authority_data)
  client_certificate     = base64decode(opentelekomcloud_cce_cluster_v3.cce_cluster.certificate_users[0].client_certificate_data)
  client_key             = base64decode(opentelekomcloud_cce_cluster_v3.cce_cluster.certificate_users[0].client_key_data)
}

# ==== AGENCY << need to add to documentation

resource "opentelekomcloud_identity_agency_v3" "cce_swr_access" {
  name        = "${local.name_base}-cce-swr"
  description = "Allow CCE to access SWR for image pulls"

  # Trustee: SWR service
  delegated_domain_name = "op_svc_swr"

  # Trustor: Your project with roles
  project_role {
    project = data.opentelekomcloud_identity_project_v3.project.name
    roles   = ["SWR Administrator"]
  }
}

# =============================================
# STEP 7: DATA Volume
# =============================================

resource "kubernetes_persistent_volume_claim_v1" "nextcloud_data" {
  provider = kubernetes.cce
  metadata {
    name      = "${local.name_base}-nc-data"
    namespace = kubernetes_namespace_v1.nextcloud.metadata[0].name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "csi-disk"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

# =============================================
# STEP 8: Nextcloud deployment
# =============================================

resource "kubernetes_namespace_v1" "nextcloud" {
  provider = kubernetes.cce
  metadata {
    name = "nextcloud"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "mysql_data" {
  provider = kubernetes.cce
  metadata {
    name      = "${local.name_base}-mysql-data"
    namespace = kubernetes_namespace_v1.nextcloud.metadata[0].name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "csi-disk"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}


resource "random_password" "mysql_root" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_deployment_v1" "mysql" {
  provider = kubernetes.cce
  metadata {
    name      = "${local.name_base}-mysql"
    namespace = kubernetes_namespace_v1.nextcloud.metadata[0].name
    labels = {
      app = "mysql"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "mysql"
      }
    }
    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }
      spec {
        container {
          image = "docker.io/library/mariadb:${var.mariadb_version}"
          name  = "mysql"
          port {
            container_port = 3306
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = random_password.mysql_root.result # Generated for init.
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "nextcloud"
          }
          env {
            name  = "MYSQL_USER"
            value = "nextcloud"
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = var.db_password
          }
          volume_mount {
            name       = "mysql-data"
            mount_path = "/var/lib/mysql"
          }
        }
        volume {
          name = "mysql-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.mysql_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "nextcloud" {
  provider = kubernetes.cce
  metadata {
    name      = "${local.name_base}-nextcloud"
    namespace = kubernetes_namespace_v1.nextcloud.metadata[0].name
    labels = {
      app = "nextcloud"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nextcloud"
      }
    }
    template {
      metadata {
        labels = {
          app = "nextcloud"
        }
      }
      spec {
        container {
          image = "docker.io/library/nextcloud:${var.nextcloud_version}"
          name  = "nextcloud"
          port {
            container_port = 80
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/www/html"
          }
          env {
            name  = "MYSQL_HOST"
            value = "${local.name_base}-mysql"
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "nextcloud"
          }
          env {
            name  = "MYSQL_USER"
            value = "nextcloud"
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = var.db_password
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.nextcloud_data.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [
    opentelekomcloud_cce_node_pool_v3.node_pool,
    kubernetes_deployment_v1.mysql
  ]
}

# Mysql (internal) service

resource "kubernetes_service_v1" "mysql" {
  provider = kubernetes.cce
  metadata {
    name      = "${local.name_base}-mysql"
    namespace = kubernetes_namespace_v1.nextcloud.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.mysql.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}

# Nextcloud (external) service

resource "kubernetes_service_v1" "nextcloud" {
  provider = kubernetes.cce
  metadata {
    name      = "${local.name_base}-nextcloud"
    namespace = kubernetes_namespace_v1.nextcloud.metadata[0].name
    annotations = {
      "kubernetes.io/elb.autocreate" = jsonencode({
        type                = "public"           # Required
        bandwidth_name      = "cce-bandwidth"   # Required for public
        bandwidth_chargemode = "traffic"        # Required for public
        bandwidth_size      = 5                 # Required for public
        bandwidth_sharetype = "PER"             # Required for public
        eip_type            = "5_bgp"           # Required for public
      })
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.nextcloud.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

output "nextcloud_url" {
  value       = "http://${kubernetes_service_v1.nextcloud.status[0].load_balancer[0].ingress[0].ip}"
  description = "Nextcloud POC URL"
}
