# S3 Module

IAM policy for Terraform backend state management in S3.

## Overview

This module contains the IAM policy required for Terraform to manage its remote state in an S3 bucket. The policy grants necessary permissions for the Terraform deployer role to read, write, and manage state files.

## Purpose

This is **not** a Terraform module that creates S3 resources. Instead, it defines the IAM permissions needed for:

- **State Storage**: Reading and writing Terraform state files to S3
- **State Locking**: Supporting state locking via DynamoDB (when configured)
- **Version Management**: Accessing versioned state files for rollback capabilities

## IAM Policy

The `iam-policy.json` file defines permissions for:

### Bucket-Level Operations
- `s3:ListBucket`: List objects in the state bucket
- `s3:GetBucketVersioning`: Check bucket versioning configuration

### Object-Level Operations
- `s3:GetObject`: Read state files
- `s3:PutObject`: Write updated state files
- `s3:DeleteObject`: Remove old state files
- `s3:GetObjectVersion`: Access specific versions of state files

## Usage

This policy should be applied to your IAM user or role that executes Terraform commands:

1. The policy is defined in `iam-policy.json`
2. Combined with other module policies via `tooling/create_iam_policies.sh`
3. Applied as a policy version to your IAM principal

## Backend Configuration

The S3 backend is configured in the root `backend.tf` with environment-specific settings in `environments/{env}/backend.hcl`:

```hcl
# environments/dev/backend.hcl
bucket = "terraform-state-<ACCOUNT_ID>-<REGION>"
region = "us-east-1"
key    = "aws-iac/ecs-webapp/dev/terraform.tfstate"
```

## Prerequisites

- S3 bucket for state storage must exist (created manually or via foundational infrastructure)
- Bucket name format: `terraform-state-ACCOUNT_ID-REGION`
- Bucket versioning should be enabled for state history
- DynamoDB table for state locking (optional but recommended)

## Security Considerations

- Policy uses least-privilege access scoped to the specific state bucket
- State files may contain sensitive information - ensure bucket encryption is enabled
- Restrict bucket access via bucket policies and IAM permissions
- Enable versioning for state recovery capabilities
