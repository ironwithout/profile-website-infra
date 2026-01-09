# IAM Module

Creates IAM roles for ECS Fargate tasks with least-privilege security model.

## Overview

This module creates two separate IAM roles required by ECS Fargate:

1. **Task Execution Role**: Used by ECS infrastructure to pull container images and send logs to CloudWatch
2. **Task Role**: Used by application containers to make AWS API calls

## Implementation

### Task Execution Role
Configured with permissions to:
- Pull images from ECR repositories (scoped via repository ARNs)
- Create and write to CloudWatch log groups matching `/ecs/${project_name}`

### Task Role
The task role is empty by default, following the principle of least privilege. Application permissions are added as needed using a single consolidated policy pattern.

A commented example in `main.tf` demonstrates the pattern for adding application permissions (S3 and DynamoDB access). This example serves as a template and should be uncommented and modified when the application requires AWS service access.

## Security Design

### Resource Scoping
All permissions use scoped resource ARNs:
- ECR: Exact repository ARNs passed via `ecr_repository_arns` variable
- CloudWatch Logs: Exact log group pattern `/ecs/${project_name}` with `:*` suffix for streams
- Application resources: Template uses `${var.project_name}-*` naming pattern

### Policy Pattern
Uses single consolidated policy approach:
- Single IAM policy document with multiple statements (one per AWS service)
- Single policy attachment to the task role
- Suitable for applications with few AWS service integrations (≤3 services)

## Module Inputs

| Name | Description | Type |
|------|-------------|------|
| `project_name` | Project name (kebab-case) | `string` |
| `ecr_repository_arns` | ECR repository ARNs for image pulls | `list(string)` |

## Module Outputs

| Name | Description |
|------|-------------|
| `task_execution_role_arn` | ARN of task execution role (for ECS task definition) |
| `task_execution_role_name` | Name of task execution role |
| `task_role_arn` | ARN of task role (for ECS task definition) |
| `task_role_name` | Name of task role |

## Usage Example

```hcl
module "iam" {
  source = "./modules/iam"

  project_name         = var.project_name
  ecr_repository_arns  = [module.ecr.repository_arn]
}
```

## IAM Permissions Required

The Terraform deployer needs these IAM permissions (see `iam-policy.json`):

- **Role Management**: Create, update, delete, tag IAM roles
- **Policy Management**: Create, update, delete, tag IAM policies  
- **Policy Attachment**: Attach/detach policies to/from roles

Total of 19 IAM actions across 3 resource types (roles, policies, policy attachments).

## CloudWatch Logs Permission Details

The task execution role can write to log groups matching:
- Exact pattern: `/ecs/${project_name}`
- All log streams within that group (`:*` suffix)
