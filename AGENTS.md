# AWS ECS Fargate IaC Project - AI Agent Instructions

## Project Architecture
This project deploys containerized web applications on AWS ECS Fargate using Terraform. The architecture follows: `Internet → Route53 → ALB (HTTPS) → ECS Fargate → ECR`, with VPC networking and CloudWatch observability.

## Module Structure Pattern
All Terraform modules follow this structure:
```
modules/<module-name>/
  ├── main.tf       # Resource definitions
  ├── variables.tf  # Input variables with descriptions
  ├── outputs.tf    # Exported values for cross-module references
  └── README.md     # Module documentation
```

Root orchestrates modules via `main.tf` with environment-specific configs in `environments/{dev,prod}/terraform.tfvars`.

## Naming Conventions
Follow consistent naming pattern for all AWS resources:
```
${var.project_name}-${var.environment}-<resource-type>
```

Examples:
- ECS Cluster: `myapp-dev-ecs-cluster`
- ALB: `myapp-prod-alb`
- Security Group: `myapp-dev-ecs-sg`
- Log Group: `/aws/ecs/myapp-dev`

Use lowercase with hyphens (kebab-case). Avoid underscores in resource names.

## Critical Module Dependencies
1. **networking** must be created first (VPC, subnets, security groups)
2. **iam** roles must exist before **ecs** (task execution + task roles)
3. **ecr** repository must exist before **ecs** task definitions
4. **alb** target group created before **ecs** service (load balancer attachment)
5. ACM certificate must be validated before **alb** HTTPS listener

When creating new modules, always expose necessary outputs for downstream dependencies.

## Security Group Pattern
Use **source-based referencing** instead of CIDR blocks for internal traffic:
```hcl
# ALB → ECS
resource "aws_security_group_rule" "alb_to_ecs" {
  source_security_group_id = aws_security_group.alb.id  # NOT cidr_blocks
  security_group_id        = aws_security_group.ecs.id
}
```

## IAM Role Convention
This project uses **separate roles** for different purposes:
- **Task Execution Role**: ECR pulls, CloudWatch logs (AWS managed `AmazonECSTaskExecutionRolePolicy`)
- **Task Role**: Application runtime permissions (custom policies only, no wildcards)
- **Terraform/CI Role**: Infrastructure deployment (OIDC-based for GitHub Actions)

Always use resource-specific ARNs in policies: `arn:aws:ecr:region:account:repository/repo-name`, never `*`.

## ECS Task Definition Requirements
- **Launch type**: Must be `FARGATE`
- **Network mode**: Must be `awsvpc` (Fargate requirement)
- **Target type**: ALB target groups must use `ip` (not `instance`)
- **Health checks**: Container must expose `/health` endpoint (30s interval)
- **Public IP**: Assign public IP in ECS service network config (for ECR pulls without NAT Gateway)
- **Secrets**: Use SSM Parameter Store references in container env vars, not inline values

## Terraform Backend Configuration
State is stored in S3 with DynamoDB locking. Backend config goes in `backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "aws-iac/ecs-webapp/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
    dynamodb_table = "terraform-state-lock"
  }
}
```
Backend resources (S3 bucket + DynamoDB table) must be bootstrapped manually before first `terraform init`.

## Environment-Specific Patterns
Variables differ by environment:
- **dev**: `ecs_desired_count = 1`, `log_retention_days = 30`, Fargate Spot
- **prod**: `ecs_desired_count = 2`, `log_retention_days = 90`, standard Fargate

Use `terraform.tfvars` files in `environments/{env}/` (gitignored), never hardcode values.

## Deployment Workflow
Standard deployment sequence:
```bash
# Infrastructure changes
terraform init
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -auto-approve

# Container deployments (CI/CD)
aws ecr get-login-password | docker login ...
docker build -t app:latest .
docker tag app:latest ${ECR_URL}:latest
docker push ${ECR_URL}:latest
aws ecs update-service --force-new-deployment  # Trigger rollout
```

For infrastructure changes, always run `terraform validate` before `plan`.

## ACM Certificate Handling
- Certificates use **DNS validation** via Route53 for auto-renewal
- **us-east-1** region required for CloudFront; otherwise use same region as ALB
- Prefer wildcard certs (`*.domain.com`) for dev/staging subdomain flexibility
- Always create `aws_acm_certificate_validation` resource to wait for validation

## Load Balancer Configuration
- **HTTP (80)**: Redirect to HTTPS (no direct forwarding)
- **HTTPS (443)**: Modern TLS policy `ELBSecurityPolicy-TLS13-1-2-2021-06`
- **Deregistration delay**: 30s (fast deployments, stateless app assumption)
- **Health check grace period**: 60s in ECS service (allow container startup)
- **Circuit breaker**: Must be enabled on ECS service for automatic rollback

## Cost Optimization Patterns
- Use **Fargate Spot** for dev/staging (add to capacity provider strategy)
- Set shorter log retention in dev (7-30 days vs 90 in prod)
- Use **public subnets + assign public IP** instead of NAT Gateway (significant cost savings)
- Consolidate multiple apps behind one ALB where possible

## Terraform Best Practices

### Code Quality
- Run `terraform fmt` before commits (enforces consistent formatting)
- Use `terraform-docs` to auto-generate module READMEs
- Pin provider versions using `~>` for minor updates: `version = "~> 5.0"`
- Validate with `tflint` and `checkov` for security/best practice scanning

### Module Development
- Keep modules focused (single responsibility principle)
- Use `description` field for all variables and outputs
- Set reasonable defaults where applicable, mark sensitive variables
- Version modules using Git tags (e.g., `v1.0.0`) for stable references
- Test modules in isolation before integration

### State Management
- Never commit `.tfstate` files
- Use workspace-based isolation for environments OR separate state files
- Enable state locking (DynamoDB) to prevent concurrent modifications
- Regular state backups (S3 versioning enabled)
- Use `terraform state mv` for refactoring, never edit state manually

### Pull Request Workflow
1. Create feature branch from `main`
2. Run `terraform fmt -recursive` and `terraform validate`
3. Generate plan: `terraform plan -out=tfplan`
4. Review plan output in PR (use GitHub Actions to post plan as comment)
5. Require approval before merge
6. Apply only from `main` branch in CI/CD or manually

## Testing Commands
```bash
# Pre-deploy validation
terraform fmt -check -recursive
terraform validate
tflint --recursive  # Lint Terraform code
checkov -d .        # Security/compliance scanning
terraform plan -out=tfplan

# Post-deploy verification
curl https://yourdomain.com/health  # Health check
curl -vI https://yourdomain.com      # SSL verification
aws ecs describe-services --cluster <cluster> --services <service>  # Verify deployment
```

## Common Pitfalls
1. Forgetting `assign_public_ip = true` in ECS service → tasks can't pull from ECR
2. Using `instance` target type with Fargate → must be `ip`
3. Hardcoding secrets in task definitions → use SSM Parameter Store
4. Missing `depends_on` for ACM validation → HTTPS listener fails
5. Wrong security group direction (egress vs ingress) → blocked traffic
6. Undocumented variables → always add `description` and `type` to all variables
7. Using `data` sources without error handling → wrap in `try()` or validate existence
8. Mixing provider versions across modules → lock versions in root `versions.tf`
9. Not using `lifecycle` blocks → leads to unwanted resource replacement (use `create_before_destroy`)
10. Forgetting to add `terraform.tfvars` to `.gitignore` → secrets exposure risk
