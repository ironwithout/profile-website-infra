# AWS Infrastructure as Code - Copilot Instructions

## Architecture Overview

This is a **Terraform-based ECS Fargate infrastructure** for deploying containerized web services on AWS. The architecture follows a modular design with clear dependency chains:

```
main.tf (root) → modules/{network, iam, acm, alb, waf, ecs}
```

**Module dependency flow**: `network` → `iam` → `acm` → `alb` → `waf` → `ecs`

Key components:
- **network**: VPC, public/private subnets, security groups
- **iam**: ECS task execution and task roles with least-privilege ECR access
- **acm**: SSL certificates for HTTPS
- **alb**: Application Load Balancer with path-based routing
- **waf**: Web Application Firewall protection
- **ecs**: Fargate cluster, task definitions, services

## Project Conventions

### Naming
- Use **kebab-case** for `project_name` (validated in [variables.tf](variables.tf#L14))
- All resources tagged as `${var.project_name}-{resource-type}`
- CloudWatch logs: `/ecs/${project_name}/${service_name}`

### Module Structure
Each module follows this pattern (see [modules/](modules/)):
```
modules/{name}/
├── main.tf           # Resources
├── variables.tf      # Inputs
├── outputs.tf        # Outputs
├── iam-policy.json   # Least-privilege IAM policy for CI/CD
└── README.md         # Module documentation
```

### Configuration Patterns
- Services defined via map variables with **optional fields and defaults** (see `ecs_services` in [variables.tf](variables.tf#L35))
- ALB routing configured through `alb_routes` variable with health check customization
- Container images referenced from ECR via `local.ecs_service_images` in [main.tf](main.tf#L8)

## Terraform Workflow

### Local Development
```bash
# Initialize with backend config
terraform init -backend-config="bucket=<BUCKET>" -backend-config="key=<KEY>" -backend-config="region=<REGION>"

# Or use backend.hcl file
terraform init -backend-config=backend.hcl

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan
```

### CI/CD (GitHub Actions)
Deployment is automated via [.github/workflows/terraform-deploy.yml](.github/workflows/terraform-deploy.yml):
- **Pull Requests**: Validates syntax and generates plan for review
- **Push to `main`**: Validates and applies infrastructure changes
- Uses OIDC for AWS authentication (no long-lived credentials)
- Backend config passed via GitHub secrets: `S3_STATE_BUCKET`, `S3_STATE_KEY`, `AWS_REGION`, `AWS_ROLE_ARN`
- Outputs are redacted in logs to protect AWS account IDs

### Setting Up GitHub OIDC for AWS
To enable GitHub Actions to authenticate with AWS without long-lived credentials:

1. **Create OIDC Identity Provider** in AWS IAM:
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`

2. **Create IAM Role** with trust policy (replace `<ACCOUNT_ID>`, `<OWNER>`, `<REPO>`):
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": {
         "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
       },
       "Action": "sts:AssumeRoleWithWebIdentity",
       "Condition": {
         "StringEquals": {
           "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
         },
         "StringLike": {
           "token.actions.githubusercontent.com:sub": "repo:<OWNER>/<REPO>:*"
         }
       }
     }]
   }
   ```

3. **Attach permissions** using the setup script:
   ```bash
   ./tooling/setup_cicd_iam.sh --type role --name github-actions-terraform
   ```

4. **Configure GitHub secrets**: `AWS_ROLE_ARN`, `AWS_REGION`, `S3_STATE_BUCKET`, `S3_STATE_KEY`

### IAM Policy Management
Use [tooling/setup_cicd_iam.sh](tooling/setup_cicd_iam.sh) to create/update IAM policies from module `iam-policy.json` files and attach them to a user or role:
```bash
./tooling/setup_cicd_iam.sh --type <user|role> --name <name>
```

## Security Configuration

### WAF Rules
The WAF module ([modules/waf/main.tf](modules/waf/main.tf)) protects the ALB with AWS Managed Rule Sets:
- **AWSManagedRulesCommonRuleSet** (priority 1): OWASP Top 10 protection
- **AWSManagedRulesKnownBadInputsRuleSet** (priority 2): Blocks known malicious patterns
- **AWSManagedRulesAmazonIpReputationList** (priority 3): Blocks IPs with poor reputation

All rules have CloudWatch metrics enabled for monitoring. Default action is `allow` - only matched threats are blocked.

## Adding New Services

1. Add service config to `ecs_services` variable in [variables.tf](variables.tf#L35)
2. Add routing config to `alb_routes` variable
3. Add ECR repository ARN to `local.ecr_repository_arns` in [main.tf](main.tf#L5)
4. Add container image to `local.ecs_service_images` in [main.tf](main.tf#L8)

## Critical Details

- **State backend**: S3 with native locking (`use_lockfile = true`), no DynamoDB needed
- **Terraform version**: `>= 1.5.0` required (see [versions.tf](versions.tf))
- **AWS provider**: `~> 5.0`
- **ECS tasks run in public subnets** with public IPs (no NAT Gateway cost)
- **Circuit breaker enabled** on ECS services with automatic rollback
- **Container Insights enabled** on ECS cluster for monitoring
