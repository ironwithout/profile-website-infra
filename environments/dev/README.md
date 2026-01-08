# Development Environment

Environment-specific configuration for the development environment.

## Setup

1. Copy the example files:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   cp backend.hcl.example backend.hcl
   ```

2. Edit `backend.hcl` with your AWS account ID:
   ```hcl
   bucket = "terraform-state-<YOUR_ACCOUNT_ID>"
   region = "us-east-1"
   key    = "dev/terraform.tfstate"
   ```

3. Edit `terraform.tfvars` with specific values (project name, region, etc.)

4. Initialize with dev backend and apply:
   ```bash
   cd ../..  # Return to root
   terraform init -backend-config=environments/dev/backend.hcl
   terraform plan -var-file=environments/dev/terraform.tfvars
   terraform apply -var-file=environments/dev/terraform.tfvars
   ```

Each environment has its own S3 state key (`dev/terraform.tfstate` vs `prod/terraform.tfstate`) to keep states isolated.

## Configuration

- **Cost Optimization**: Uses Fargate Spot, shorter log retention, minimal replicas
- **Network**: Uses public subnets with auto-assign public IP (no NAT Gateway)
- **Secrets**: Stored in SSM Parameter Store, referenced in task definitions

## Important

⚠️ **Do not commit these files** (both are gitignored):
- `terraform.tfvars` - Contains environment-specific configuration
- `backend.hcl` - Contains your AWS account ID
