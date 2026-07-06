# Nextcloud T-Cloud Terraform Samples

This repository contains sample Terraform configurations for deploying Nextcloud on OpenTelekomCloud T-Cloud using two different approaches:

- **CCE (Cloud Container Engine)**: Kubernetes-based deployment with MariaDB and Nextcloud containers
- **ECS (Elastic Cloud Server)**: Single VM deployment using Docker

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [OpenTelekomCloud Account](https://www.telekomcloud.com/) with appropriate permissions
- OpenTelekomCloud Provider credentials

## Projects

### CCE Nextcloud Deployment

Deploys Nextcloud on Kubernetes with:
- CCE cluster with worker nodes
- Automatic VPC, subnet, and networking
- NAT gateway for internet access
- MariaDB and Nextcloud containers
- Persistent storage for both database and application

#### Usage
1. Navigate to the cce-nextcloud directory
2. Copy terraform.tfvars.example to terraform.tfvars
3. Edit terraform.tfvars with your credentials and configuration
4. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### ECS Docker Deployment

Deploys Nextcloud on a single VM with:
- Ubuntu VM with Docker
- Cloud-init configuration for automatic Docker and Nextcloud setup
- Floating IP for external access
- Security groups for SSH, HTTP, and HTTPS access

#### Usage
1. Navigate to the ecs-docker directory
2. Copy terraform.tfvars.example to terraform.tfvars
3. Edit terraform.tfvars with your credentials and configuration
4. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

Both projects require the following information:
- **Domain Name**: Your OTC domain ID
- **Project/Tenant Name**: Your OTC project name
- **Access Key/Secret Key**: Your OTC API credentials
- **Region**: Either eu-nl or eu-de
- **SSH Public Key**: Your SSH public key for VM access

## Security Notes

- Never commit terraform.tfvars files to version control
- Use strong, unique passwords for database credentials
- Store secrets in a secure vault when possible
- Review security group rules before production use

## Cleanup

To destroy all resources and avoid continued charges:
```bash
terraform destroy
```

## License

MIT License

## Contributing

Feel free to submit pull requests with improvements or bug fixes.
