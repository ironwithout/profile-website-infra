# ECR Module

## Overview
This module creates an AWS Elastic Container Registry (ECR) repository for storing Docker container images. It includes lifecycle policies for image retention, security scanning, and encryption.

## Features
- **Image Scanning**: Automated vulnerability scanning on image push
- **Lifecycle Policies**: 
  - Retain last N tagged images (configurable)
  - Expire untagged images after X days (configurable)
- **Encryption**: AES256 or KMS encryption at rest
- **Tag Mutability**: Configurable (MUTABLE or IMMUTABLE)

## Architecture
```
CI/CD Pipeline → ECR Repository → ECS Fargate
                 ↓
            Image Scanning
            Lifecycle Policy
            Encryption
```

## Usage
```hcl
module "ecr" {
  source = "./modules/ecr"

  project_name         = "myapp"
  environment          = "dev"

  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  encryption_type      = "AES256"
  kms_key_arn          = null
  max_image_count      = 30
  untagged_image_days  = 7
}
```

## Inputs
| Name | Description | Type |
|------|-------------|------|
| project_name | Project name for resource naming | string |
| environment | Environment (dev/prod/staging) | string |
| image_tag_mutability | Image tag mutability (MUTABLE/IMMUTABLE) | string |
| scan_on_push | Enable image scanning on push | bool |
| encryption_type | Encryption type (AES256/KMS) | string |
| kms_key_arn | KMS key ARN (required if encryption_type=KMS) | string |
| max_image_count | Max tagged images to retain | number |
| untagged_image_days | Days to retain untagged images | number |

## Outputs
| Name | Description |
|------|-------------|
| repository_url | ECR repository URL (for docker push/pull) |
| repository_arn | ECR repository ARN |
| repository_name | ECR repository name |
| registry_id | ECR registry ID |

## Lifecycle Policy Details

### Tagged Images
- Keeps the last `max_image_count` images with tags starting with "v" (e.g., v1.0.0)
- Older images are automatically deleted

### Untagged Images
- Expires after `untagged_image_days` days
- Helps clean up intermediate build images

## Security Best Practices
1. **Image Scanning**: Enabled by default to detect vulnerabilities
2. **Encryption**: AES256 encryption at rest (can upgrade to KMS)
3. **Tag Immutability**: Consider IMMUTABLE for production to prevent tag overwrites
4. **Access Control**: Use IAM policies for least-privilege access

## IAM Requirements
This module requires the following IAM permissions (see `iam-policy.json`):
- `ecr:CreateRepository`, `ecr:DeleteRepository`, `ecr:DescribeRepositories`
- `ecr:PutLifecyclePolicy`, `ecr:GetLifecyclePolicy`
- `ecr:PutImageTagMutability`, `ecr:PutImageScanningConfiguration`

## Docker Usage Examples

### Login to ECR
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <registry_id>.dkr.ecr.us-east-1.amazonaws.com
```

### Build and Push Image
```bash
docker build -t myapp:v1.0.0 .
docker tag myapp:v1.0.0 <repository_url>:v1.0.0
docker push <repository_url>:v1.0.0
```

### Pull Image
```bash
docker pull <repository_url>:v1.0.0
```

## Cost Optimization
- Lifecycle policies automatically remove old images to reduce storage costs
- Untagged image expiration prevents accumulation of build artifacts
- Default settings balance retention needs with cost efficiency

## Environment-Specific Recommendations

### Development
- `image_tag_mutability`: MUTABLE (allows tag overwrites)
- `max_image_count`: 10-20 (fewer images needed)
- `untagged_image_days`: 3-7 (faster cleanup)

### Production
- `image_tag_mutability`: IMMUTABLE (prevents accidental overwrites)
- `max_image_count`: 30-50 (retain more history)
- `untagged_image_days`: 7-14 (allow time for investigation)
- Consider KMS encryption for enhanced security
