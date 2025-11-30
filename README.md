# AWS ECS Fargate Infrastructure as Code

Terraform project for deploying containerized web applications on AWS ECS Fargate with full observability and HTTPS load balancing.

## Architecture

```
Internet → Route53 → ALB (HTTPS) → ECS Fargate → ECR
                      ↓
                 CloudWatch Logs
```

**Module Architecture**: Root layer orchestrates reusable modules. Currently implements `network` module (VPC, subnets, security groups). Future modules: IAM, ECR, ECS, ALB, Route53.

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with credentials
- AWS account with appropriate permissions

## Project Structure

```
.
├── main.tf                 # Root orchestration
├── variables.tf            # Root variables
├── outputs.tf              # Root outputs
├── versions.tf             # Provider versions
├── backend.tf              # S3 backend config
├── docs/                   # Project documentation
│   └── *.md
├── modules/
│   └── <module-name>/      # Self-contained infrastructure modules
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── iam-policy.json # IAM policy for this module
│       └── README.md
└── environments/
    └── <env>/              # Environment-specific configs (dev, prod, staging)
        ├── backend.hcl
        ├── terraform.tfvars.example
        └── README.md
```

**Key Patterns**:
- Root `main.tf` orchestrates modules, never defines resources directly
- Each module is self-contained with its own IAM policy requirements
- Environment-specific configs in `environments/{env}/` directories
- Separate S3 state files per environment

## Quick Start

### 1. Backend Setup (First Time Only)

Follow the [Backend Setup Guide](docs/BACKEND.md) to:
- Create S3 bucket for state storage
- Configure bucket security (versioning, encryption)
- Create and attach IAM policies for backend access

### 2. Configure Environment

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (project_name, region, etc.)
```

### 3. Initialize Terraform

```bash
cd ../..
terraform init -backend-config=environments/dev/backend.hcl
```

### 4. Validate and Format

```bash
terraform fmt -recursive
terraform validate
```

### 5. Deploy

```bash
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

## Key Concepts

### Naming Convention

All resources follow: `${project_name}-${environment}-<resource-type>`

Examples:
- VPC: `myapp-dev-vpc`
- ECS Cluster: `myapp-prod-ecs-cluster`
- ALB: `myapp-dev-alb`

### Environment Management

Each environment has isolated state via partial backend configuration:
- Common config in `backend.tf` (bucket, region)
- Environment-specific state key in `environments/{env}/backend.hcl`

Switch environments:
```bash
terraform init -reconfigure -backend-config=environments/prod/backend.hcl
```

### Module Dependencies

1. `network` - VPC, subnets, security groups (✅ implemented)
2. `iam` - Task execution and task roles
3. `ecr` - Container registry
4. `ecs` - Fargate cluster and service
5. `alb` - Application Load Balancer
6. `route53` - DNS configuration

Each module contains its own `iam-policy.json` with minimum required IAM permissions.

## Development

### Testing & Validation

```bash
# Format check
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Security scan (requires checkov)
checkov -d .

# Lint (requires tflint)
tflint --recursive
```

### Contributing

1. Create feature branch from `main`
2. Run `terraform fmt` and `terraform validate`
3. Generate plan for review
4. Submit PR with plan output
5. Apply only after approval

## Best Practices

### Security

- ✅ Never commit `.tfvars` files (gitignored)
- ✅ Each module defines minimum IAM permissions in `iam-policy.json`
- ✅ S3 backend uses encryption and versioning
- 🔒 Use SSM Parameter Store for secrets
- 🔒 Enable CloudTrail for audit logging
- 🔒 Review security group rules regularly

### Cost Optimization

- Use Fargate Spot for dev/staging
- Deploy to public subnets (no NAT Gateway costs)
- Consolidate apps behind single ALB
- Set appropriate log retention periods

## Documentation

- **Project docs**: [docs/README.md](docs/README.md) - See full list of available guides
- **AI agent guide**: [AGENTS.md](AGENTS.md)
- **Module docs**: See each module's `README.md` and `iam-policy.json`

## License

MIT
