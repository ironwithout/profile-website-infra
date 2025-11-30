# Production Environment

This directory contains environment-specific configuration for the **production** environment.

## Setup

1. Copy the example file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your specific values (project name, region, etc.)

3. Initialize with prod backend and apply:
   ```bash
   cd ../..  # Return to root
   terraform init -backend-config=environments/prod/backend.hcl
   terraform plan -var-file=environments/prod/terraform.tfvars
   terraform apply -var-file=environments/prod/terraform.tfvars
   ```

**Note**: Each environment has its own S3 state key (`dev/terraform.tfstate` vs `prod/terraform.tfstate`) to keep states isolated.

## Configuration Notes

- **High Availability**: Uses 3 AZs, multiple task replicas, standard Fargate
- **Logging**: 90-day CloudWatch log retention
- **Security**: TLS 1.3, strict security policies, regular backups

## Important

⚠️ Never commit `terraform.tfvars` - it's gitignored and may contain sensitive values.
⚠️ Always review `terraform plan` output before applying to production.
