terraform {
  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = ">= 1.36.68"
    }
  }
}

provider "opentelekomcloud" {
  auth_url    = "https://iam.${var.region}.otc.t-systems.com:443/v3"
  domain_name = var.domain_name
  tenant_name = var.tenant_name
  enterprise_project_id = var.enterprise_project_id
  access_key  = var.access_key
  secret_key  = var.secret_key
  region      = var.region
}