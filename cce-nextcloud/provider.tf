terraform {
  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = ">= 1.36.68"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

# Configure OpenTelekomCloud Provider
provider "opentelekomcloud" {
  auth_url    = "https://iam.${var.region}.otc.t-systems.com:443/v3"
  domain_name = var.domain_name
  tenant_name = var.project_name
  access_key  = var.access_key
  secret_key  = var.secret_key
  region      = var.region
}

# Kubernetes provider will be configured after cluster creation
# This is a placeholder - actual config will be in a separate file
