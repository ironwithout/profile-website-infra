# AWS ECS Fargate Infrastructure as Code

Modular Terraform infrastructure for deploying containerized applications on AWS ECS Fargate with optional Application Load Balancer and full CloudWatch observability.

## Architecture

```
Internet → [ALB (HTTP/HTTPS)] → ECS Fargate Tasks → ECR
              ↓                        ↓
         CloudWatch               CloudWatch Logs
```

**Flexible Deployment Options**:
- Direct container access (no ALB) for minimal setup
- ALB with path/host-based routing for web applications
- Public or private subnet placement with auto-configuration

**Module Architecture**: Root orchestrates reusable, self-contained modules.

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with credentials
- AWS account with appropriate permissions

## Project Structure

```
.
├── main.tf                 # Root orchestration layer
├── variables.tf            # Root input variables
├── outputs.tf              # Root outputs
├── data.tf                 # Data sources
├── versions.tf             # Provider versions & default tags
├── backend.tf              # S3 backend config
├── AGENTS.md               # AI agent guidelines
├── modules/                # Self-contained infrastructure modules
│   ├── network/            # VPC, subnets, security groups
│   ├── iam/                # ECS task execution and task roles
│   ├── ecs/                # Fargate cluster and services
│   ├── alb/                # Application Load Balancer (optional)
│   ├── acm/                # SSL/TLS certificates (optional)
│   ├── waf/                # Web Application Firewall (optional)
│   └── s3/                 # IAM policy for backend state (no resources)
└── tooling/
    └── create_iam_policies.sh  # IAM policy management script
```

**Module Structure**: Each module contains:
- `main.tf` - Resource definitions
- `variables.tf` - Module inputs
- `outputs.tf` - Module outputs
- `iam-policy.json` - IAM permissions required
- `README.md` - Documentation

**Key Patterns**:
- Root orchestrates modules, never defines resources directly
- Each module is self-contained with own IAM policy
- S3 backend for remote state storage
- Simplified variable interface with sensible defaults

## Quick Start

### 1. Backend Setup (First Time Only)

Create an S3 bucket for Terraform state:

```bash
# Set your values
export AWS_REGION="us-east-1"
export BUCKET_NAME="terraform-state-profile-website"

# Create bucket
aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}"

# Enable versioning (for state recovery)
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### 2. Configure IAM Permissions

Each module has an `iam-policy.json` defining required permissions. Use the policy management script:

```bash
# Combine all module policies
./tooling/create_iam_policies.sh

# This creates/updates policies for each module:
# - terraform-profile-website-network
# - terraform-profile-website-iam
# - terraform-profile-website-ecs
# - terraform-profile-website-alb
# - terraform-profile-website-s3

# Attach policies to your IAM user/role via AWS Console or CLI
```

### 3. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl

# Edit backend.hcl with your bucket name
# Edit terraform.tfvars with your configuration:
#   - AWS account ID and region
#   - ECR repository ARNs
#   - ECS service definitions
#   - ALB, ACM, WAF configuration
```

### 4. Initialize Terraform

```bash
terraform init -backend-config=backend.hcl
```

### 5. Deploy

```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Key Concepts

### Naming Convention

All resources follow: `${project_name}-<resource-type>`

Examples:
- VPC: `myapp-vpc`
- ECS Cluster: `myapp-ecs-cluster`
- ALB: `myapp-alb`

### Simplified Service Configuration

ECS services use a minimal configuration with sensible defaults:

```hcl
ecs_services = {
  api = {
    # Required only
    container_name  = "api"
    container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-api"
    container_port  = 3000
    
    # Optional - override defaults
    task_cpu           = "512"    # default: "256"
    task_memory        = "1024"   # default: "512"
    desired_count      = 2        # default: 1
    log_retention_days = 3        # default: 7
  }
}
```

**Auto-configuration**:
- `use_private_subnets`: Defaults to `true` if ALB enabled, `false` otherwise
- `assign_public_ip`: Defaults to `false` for private subnets, `true` for public

### Application Load Balancer

The ALB module is **optional** and conditionally deployed:

```hcl
# Disable for direct container access
enable_alb = false

# Enable with path/host-based routing
enable_alb = true
alb_routes = {
  api = {
    path_pattern = "/api/*"
    priority     = 100
  }
  web = {
    host_header  = "app.example.com"
    path_pattern = "/*"
    priority     = 200
  }
}
```

**Features**:
- HTTP listener (port 80) with configurable routing
- Health checks per service
- Integration with ECS target groups
- Deletion protection (configurable)

### Backend Configuration

Terraform state is stored remotely in S3 via partial backend configuration:
- Common backend settings in `backend.tf`
- Deployment-specific settings in `backend.hcl`

```hcl
# backend.tf
terraform {
  backend "s3" {
    # bucket, region, and key loaded from backend.hcl
    use_lockfile = true
  }
}

# backend.hcl
bucket = "terraform-state-<ACCOUNT_ID>"
region = "us-east-1"
key    = "terraform.tfstate"
```

### Implemented Modules

| Module | Description |
|--------|-------------|
| **network** | VPC, public subnets, security groups with source-based rules |
| **iam** | ECS task execution role, task role with ECR permissions |
| **ecs** | Fargate cluster, services, CloudWatch logs |
| **alb** | Application Load Balancer with path/host routing (optional) |
| **s3** | IAM permissions for Terraform backend (no resources) |

Each module includes:
- Complete resource definitions in `main.tf`
- IAM policy document in `iam-policy.json`
- Comprehensive README with examples

## Development

### Testing & Validation

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan with configuration
terraform plan -var-file=terraform.tfvars

# Security scan (optional - requires checkov)
checkov -d .

# Lint (optional - requires tflint)
tflint --recursive
```

### IAM Policy Management

When adding or modifying modules:

1. Update the module's `iam-policy.json`
2. Run policy generation script:
   ```bash
   ./tooling/create_iam_policies.sh $user
   ```
3. Script will create/update IAM policy versions automatically
4. Policies are versioned (max 5 versions per policy)

See module READMEs and [AGENTS.md](AGENTS.md) for detailed IAM workflows.

### Contributing

1. Create feature branch from `main`
2. Run `terraform fmt -recursive` and `terraform validate`
3. Test changes thoroughly
4. Generate plan for review: `terraform plan -var-file=terraform.tfvars -out=plan.out`
5. Submit PR with plan output
6. Apply only after approval

## Best Practices

### Security

- ✅ Never commit `.tfvars` or `.hcl` files with real values (gitignored)
- ✅ Each module defines minimum IAM permissions in `iam-policy.json`
- ✅ S3 backend uses encryption, versioning, and public access block
- ✅ Security groups use source-based references (not CIDR blocks)
- ✅ Task role has minimal ECR permissions (read-only)
- 🔒 Store secrets in AWS SSM Parameter Store or Secrets Manager
- 🔒 Enable CloudTrail for audit logging
- 🔒 Review security groups before production deployment
- 🔒 Enable ALB deletion protection for production

### Cost Optimization

- Use `enable_alb = false` in dev to avoid ALB costs (~$16/month)
- Deploy dev services to public subnets (no NAT Gateway needed)
- Use Fargate Spot for non-critical workloads (up to 70% savings)
- Adjust `log_retention_days` based on needs (3 for dev, 30+ for prod)
- Consolidate multiple apps behind single ALB
- Set appropriate `desired_count` per environment (1 for dev, 2+ for prod)

## Documentation

- **[AGENTS.md](AGENTS.md)** - AI agent guidelines, module patterns, IAM workflows
- **Module READMEs**:
  - [network/](modules/network/README.md) - VPC, subnets, security groups
  - [iam/](modules/iam/README.md) - ECS task execution and task roles
  - [ecs/](modules/ecs/README.md) - Fargate cluster and services
  - [alb/](modules/alb/README.md) - Application Load Balancer
  - [acm/](modules/acm/README.md) - SSL/TLS certificates
  - [waf/](modules/waf/README.md) - Web Application Firewall
  - [s3/](modules/s3/README.md) - Backend state IAM policy

## License

MIT
