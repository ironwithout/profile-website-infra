# AWS ECS Fargate Infrastructure

Terraform-based infrastructure for deploying containerized web services on AWS using ECS Fargate, with HTTPS, WAF protection, and automated CI/CD deployments.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Internet  │────▶│     WAF     │────▶│     ALB     │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┼──────────────────────────┐
                    │ VPC                      │                          │
                    │  ┌───────────────────────▼───────────────────────┐  │
                    │  │ Public Subnets                                │  │
                    │  │  ┌─────────────┐      ┌─────────────┐         │  │
                    │  │  │ ECS Fargate │      │ ECS Fargate │         │  │
                    │  │  │   Task(s)   │      │   Task(s)   │         │  │
                    │  │  └─────────────┘      └─────────────┘         │  │
                    │  └───────────────────────────────────────────────┘  │
                    └─────────────────────────────────────────────────────┘
```

**Key Components:**
- **VPC** with public/private subnets across 2 AZs
- **Application Load Balancer** with HTTPS (ACM certificate)
- **WAF** with AWS Managed Rules (OWASP Top 10, bad inputs, IP reputation)
- **ECS Fargate** cluster running containerized services
- **CloudWatch** logs with Container Insights enabled

## Prerequisites

- AWS Account with admin access
- AWS CLI installed and configured
- Terraform >= 1.5.0
- GitHub repository (for CI/CD)

## Initial Setup

### 1. Create S3 Bucket for Terraform State

```bash
# Replace with your desired bucket name and region
aws s3api create-bucket \
  --bucket terraform-state-<project-name> \
  --region us-east-1

# Enable versioning (recommended)
aws s3api put-bucket-versioning \
  --bucket terraform-state-<project-name> \
  --versioning-configuration Status=Enabled
```

### 2. Set Up GitHub OIDC Authentication in AWS

This allows GitHub Actions to authenticate without long-lived credentials.

#### Create OIDC Identity Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Create IAM Role for GitHub Actions

1. Create the trust policy file (`github-trust-policy.json`):

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

2. Create the role:

```bash
aws iam create-role \
  --role-name github-actions-terraform \
  --assume-role-policy-document file://github-trust-policy.json
```

### 3. Create and Attach IAM Policies

Use the setup script to create least-privilege policies from module definitions and attach them to the role:

```bash
# Creates policies from modules/*/iam-policy.json and attaches to the role
./tooling/setup_cicd_iam.sh --type role --name github-actions-terraform
```

For local development with an IAM user instead:

```bash
./tooling/setup_cicd_iam.sh --type user --name terraform-deployer
```

### 4. Configure GitHub Repository Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ROLE_ARN` | ARN of the GitHub Actions IAM role | `arn:aws:iam::123456789012:role/github-actions-terraform` |
| `AWS_REGION` | AWS region for deployment | `aws-region` |
| `S3_STATE_BUCKET` | S3 bucket for Terraform state | `terraform-state-bucket` |
| `S3_STATE_KEY` | State file path in bucket | `terraform-state-key` |

### 5. Configure Terraform Variables

Copy and customize the backend configuration:

```bash
cp backend.hcl.example backend.hcl
# Edit backend.hcl with your S3 bucket details
```

Update `variables.tf` or create a `terraform.tfvars` file:

```hcl
project_name = "my-project"
domain_name  = "example.com"
aws_region   = "aws-region"
```

### 6. Initialize and Deploy

#### Local Deployment

```bash
# Initialize Terraform
terraform init -backend-config=backend.hcl

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

#### CI/CD Deployment

Push to `main` branch to trigger automatic deployment via GitHub Actions.

## Adding New Services

1. Add ECR repository ARN to `local.ecr_repository_arns` in `main.tf`
2. Add container image to `local.ecs_service_images` in `main.tf`
3. Add service configuration to `ecs_services` variable
4. Add ALB routing configuration to `alb_routes` variable

Example service configuration:

```hcl
# In terraform.tfvars or variables.tf
ecs_services = {
  api = {
    container_name = "api"
    container_port = 8080
    task_cpu       = "512"
    task_memory    = "1024"
    desired_count  = 2
  }
}

alb_routes = {
  api = {
    path_pattern      = "/api/*"
    priority          = 10
    health_check_path = "/api/health"
  }
}
```

## Module Overview

| Module | Purpose |
|--------|---------|
| `network` | VPC, subnets, security groups, internet gateway |
| `iam` | ECS task execution and task roles with least-privilege ECR access |
| `acm` | SSL/TLS certificates for HTTPS |
| `alb` | Application Load Balancer with path-based routing |
| `waf` | Web Application Firewall with AWS Managed Rules |
| `ecs` | Fargate cluster, task definitions, services |

## Project Structure

```
├── main.tf              # Root module orchestrating all sub-modules
├── variables.tf         # Input variables with defaults
├── outputs.tf           # Output values
├── backend.tf           # S3 backend configuration
├── data.tf              # Data sources
├── versions.tf          # Provider version constraints
├── backend.hcl.example  # Backend config template
├── modules/
│   ├── network/         # VPC and networking
│   ├── iam/             # IAM roles and policies
│   ├── acm/             # SSL certificates
│   ├── alb/             # Load balancer
│   ├── waf/             # Web application firewall
│   └── ecs/             # ECS cluster and services
└── tooling/
    └── setup_cicd_iam.sh  # CI/CD IAM policy setup script
```

## Cost Considerations

- **No NAT Gateway**: ECS tasks run in public subnets with public IPs to avoid NAT Gateway costs (~$32/month per AZ)
- **Fargate Spot**: Consider using Fargate Spot for non-production workloads (up to 70% savings)
- **Right-sizing**: Default task size is 256 CPU / 512 MB memory - adjust based on actual needs

## Security Features

- **WAF Protection**: OWASP Top 10, known bad inputs, IP reputation blocking
- **HTTPS Only**: ALB redirects HTTP to HTTPS
- **Least-Privilege IAM**: Task roles scoped to specific ECR repositories
- **No Long-Lived Credentials**: GitHub Actions uses OIDC for AWS authentication
- **Circuit Breaker**: ECS services automatically rollback failed deployments

## License

MIT
