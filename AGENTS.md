# AWS ECS Fargate Infrastructure

Modular Terraform for deploying containerized apps on AWS ECS Fargate. Root orchestrates reusable modules: `network`, `iam`, and `ecs`. Each environment has isolated S3 state via partial backend config.

## Architecture Principles

**ECR Repositories**: ECR repositories are **not** managed by this infrastructure. They should be created manually or in a separate foundational infrastructure repository. This infrastructure references existing ECR repositories via input variables.

**Module Pattern**: Modules must be self-contained with own `terraform` block, `variables.tf`, `outputs.tf`, and `README.md`. Root `main.tf` only invokes modules, never defines resources.

## Naming & Tagging

**Naming**: `${project_name}-${environment}-<resource-type>` (e.g., `myapp-dev-vpc`)
- `project_name`: kebab-case only (validated)
- `environment`: `dev|prod` (validated)

**Tags**: Auto-applied via `versions.tf` `default_tags` - never add `Project`, `Environment`, or `ManagedBy` tags manually.

## Module Pattern

Modules must be self-contained with own `terraform` block, `variables.tf`, `outputs.tf`, and `README.md`. Root `main.tf` only invokes modules, never defines resources. See each module's README for implementation details.

## Security Group Pattern

**Always use source-based references** for internal traffic, not CIDR blocks:
```hcl
# ✅ Correct - reference security group ID
resource "aws_security_group_rule" "alb_to_ecs" {
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs.id
}

# ❌ Avoid - hardcoded CIDR
cidr_blocks = ["10.0.0.0/16"]
```
See `modules/network/main.tf` resource `aws_security_group_rule.alb_to_ecs`.

## Environment Workflow

### State Isolation
Backend configuration is in `backend.tf`, environment-specific settings in `environments/{env}/backend.hcl`:
```hcl
# backend.tf
backend "s3" {
  # bucket, region, and key from backend.hcl
  use_lockfile = true
}

# environments/dev/backend.hcl
bucket = "terraform-state-<ACCOUNT_ID>-<REGION>"
region = "us-east-1"
key    = "aws-iac/ecs-webapp/dev/terraform.tfstate"
```

### Commands
```bash
terraform init -backend-config=environments/dev/backend.hcl
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

Always run from root with both flags. Switch environments: `terraform init -reconfigure -backend-config=environments/prod/backend.hcl`

## IAM Policy Management

Follow **incremental least-privilege approach** when adding modules. Update policy versions (not replacements) using `aws iam create-policy-version`. See `iam-policies/README.md` for full workflow.

## Adding New Modules

1. Create `modules/<name>/` with required files
2. Update root `main.tf` to invoke module
3. Add IAM permissions to `iam-policies/terraform-deployer-<scope>.json`
4. Update IAM policy version in AWS (see `iam-policies/README.md`)
