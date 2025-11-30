# AWS ECS Fargate Infrastructure as Code

Terraform project for deploying containerized web applications on AWS ECS Fargate with full observability and HTTPS load balancing.

## Architecture

```
Internet → Route53 → ALB (HTTPS) → ECS Fargate → ECR
                      ↓
                 CloudWatch Logs
```

## Project Structure

```
.
├── main.tf                 # Root orchestration
├── variables.tf            # Root variables
├── outputs.tf              # Root outputs
├── versions.tf             # Provider versions
├── backend.tf              # S3 backend config
├── modules/
│   └── networking/         # VPC, subnets, security groups
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── environments/
    ├── dev/
    │   ├── terraform.tfvars.example
    │   └── README.md
    └── prod/
        ├── terraform.tfvars.example
        └── README.md
```

## Quick Start

1. **Clone and configure**:
   ```bash
   cd environments/dev
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform**:
   ```bash
   cd ../..
   terraform init
   ```

3. **Validate configuration**:
   ```bash
   terraform fmt -recursive
   terraform validate
   ```

4. **Deploy infrastructure**:
   ```bash
   terraform plan -var-file=environments/dev/terraform.tfvars
   terraform apply -var-file=environments/dev/terraform.tfvars
   ```

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with credentials
- AWS account with appropriate permissions

## Module Dependencies

1. `networking` - VPC, subnets, security groups (created first)
2. `iam` - Task execution and task roles (TODO)
3. `ecr` - Container registry (TODO)
4. `ecs` - Fargate cluster and service (TODO)
5. `alb` - Application Load Balancer (TODO)
6. `route53` - DNS configuration (TODO)

## Naming Convention

All resources follow: `${project_name}-${environment}-<resource-type>`

Examples:
- VPC: `myapp-dev-vpc`
- ECS Cluster: `myapp-prod-ecs-cluster`
- ALB: `myapp-dev-alb`

## Environment Differences

| Feature | Dev | Prod |
|---------|-----|------|
| Task Count | 1 | 2+ |
| Fargate Type | Spot | Standard |
| Log Retention | 30 days | 90 days |
| Availability Zones | 2 | 3 |

## Testing

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

## Contributing

1. Create feature branch from `main`
2. Run `terraform fmt` and `terraform validate`
3. Generate plan for review
4. Submit PR with plan output
5. Apply only after approval

## Security

- Never commit `.tfvars` files (gitignored)
- Use SSM Parameter Store for secrets
- Enable CloudTrail for audit logging
- Review security group rules regularly

## Cost Optimization

- Use Fargate Spot for dev/staging
- Deploy to public subnets (no NAT Gateway)
- Consolidate apps behind single ALB
- Set appropriate log retention periods

## Documentation

See `AGENTS.md` for detailed AI agent instructions and architecture patterns.

## License

MIT
