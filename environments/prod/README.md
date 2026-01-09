# Production Environment

Environment-specific configuration for the production environment.

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
   key    = "prod/terraform.tfstate"
   ```

3. Edit `terraform.tfvars` with specific values (project name, region, etc.)

4. Initialize with prod backend and apply:
   ```bash
   cd ../..  # Return to root
   terraform init -backend-config=environments/prod/backend.hcl
   terraform plan -var-file=environments/prod/terraform.tfvars
   terraform apply -var-file=environments/prod/terraform.tfvars
   ```

Each environment has its own S3 state key (`dev/terraform.tfstate` vs `prod/terraform.tfstate`) to keep states isolated.

## Important

⚠️ `terraform.tfvars` is gitignored and must not be committed (may contain sensitive values).
⚠️ Always review `terraform plan` output before applying to production.
