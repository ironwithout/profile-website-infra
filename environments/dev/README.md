# Development Environment

This directory contains environment-specific configuration for the **development** environment.

## Setup

1. Copy the example file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your specific values (project name, region, etc.)

3. Initialize with dev backend and apply:
   ```bash
   cd ../..  # Return to root
   terraform init -backend-config=environments/dev/backend.hcl
   terraform plan -var-file=environments/dev/terraform.tfvars
   terraform apply -var-file=environments/dev/terraform.tfvars
   ```

**Note**: Each environment has its own S3 state key (`dev/terraform.tfstate` vs `prod/terraform.tfstate`) to keep states isolated.

## Configuration Notes

- **Cost Optimization**: Dev uses Fargate Spot, shorter log retention, minimal replicas
- **Network**: Uses public subnets with auto-assign public IP (no NAT Gateway)
- **Secrets**: Store in SSM Parameter Store, reference in task definitions

## Important

⚠️ Never commit `terraform.tfvars` - it's gitignored and may contain sensitive values.
