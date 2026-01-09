# ECS Module

Creates an ECS Fargate cluster, task definition, and service for running containerized applications.

## Overview

This module creates the ECS infrastructure including cluster, task definition with container specifications, CloudWatch log group, and ECS service for managing task instances.

## Implementation

- **ECS Cluster**: Fargate cluster with optional Container Insights
- **Task Definition**: Defines container image, resources (CPU/memory), IAM roles, and logging
- **ECS Service**: Manages task instances with configurable desired count and deployment settings
- **CloudWatch Logs**: Log group matching pattern `/ecs/${project_name}-${environment}`
- **Health Checks**: Configurable container health checks
- **Deployment**: Circuit breaker and rollback enabled by default

## Container Configuration

The task definition references:
- ECR repository for container images
- Task execution role (pulls images, writes logs)
- Task role (application AWS API access)
- CloudWatch log configuration

## Deployment Strategy

- **Maximum Percent**: 200% (allows new tasks before terminating old ones)
- **Minimum Healthy Percent**: 100% (maintains full capacity during deployment)
- **Circuit Breaker**: Enabled with automatic rollback on failure
- **Task Definition Changes**: Ignored in service lifecycle to prevent unnecessary redeployments

## Network Configuration

Tasks run in awsvpc network mode with:
- Configurable subnet placement (public or private)
- Security group assignment
- Optional public IP assignment (required for public subnets without NAT)

## Module Inputs

| Name | Description | Type |
|------|-------------|------|
| `project_name` | Project name (kebab-case) | `string` |
| `environment` | Environment (dev/prod) | `string` |
| `subnet_ids` | Subnet IDs for ECS tasks | `list(string)` |
| `ecs_security_group_id` | Security group ID for ECS tasks | `string` |
| `task_execution_role_arn` | Task execution role ARN | `string` |
| `task_role_arn` | Task role ARN | `string` |
| `ecr_repository_url` | ECR repository URL | `string` |
| `container_image_tag` | Docker image tag | `string` |
| `container_name` | Container name | `string` |
| `container_port` | Container port | `number` |
| `task_cpu` | CPU units (256, 512, 1024, 2048, 4096) | `string` |
| `task_memory` | Memory in MB | `string` |
| `desired_count` | Desired task count | `number` |
| `launch_type` | FARGATE or FARGATE_SPOT | `string` |
| `log_retention_days` | CloudWatch log retention days | `number` |
| `aws_region` | AWS region for CloudWatch logs | `string` |

## Module Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ECS cluster ID |
| `cluster_arn` | ECS cluster ARN |
| `cluster_name` | ECS cluster name |
| `service_id` | ECS service ID |
| `service_name` | ECS service name |
| `task_definition_arn` | Task definition ARN |
| `log_group_name` | CloudWatch log group name |

## Usage Example

```hcl
module "ecs" {
  source = "./modules/ecs"

  project_name             = var.project_name
  environment              = var.environment
  
  subnet_ids               = module.network.public_subnet_ids
  ecs_security_group_id    = module.network.ecs_security_group_id
  
  task_execution_role_arn  = module.iam.task_execution_role_arn
  task_role_arn            = module.iam.task_role_arn
  
  ecr_repository_url       = module.ecr.repository_url
  container_image_tag      = "v1.0.0"
  
  task_cpu                 = "256"
  task_memory              = "512"
  desired_count            = 1
  launch_type              = "FARGATE"
  
  aws_region               = data.aws_region.current.name
}
```

## IAM Permissions Required

The Terraform deployer needs these IAM permissions (see `iam-policy.json`):

- **Cluster Management**: Create, update, delete ECS clusters
- **Task Definition Management**: Register, deregister task definitions
- **Service Management**: Create, update, delete ECS services
- **CloudWatch Logs Management**: Create, configure log groups
- **IAM PassRole**: Pass IAM roles to ECS tasks

Total of 28 ECS and CloudWatch Logs actions.

## Health Check Configuration

Default health check:
- Command: `curl -f http://localhost:3000/health || exit 1`
- Interval: 30 seconds
- Timeout: 5 seconds
- Retries: 3
- Start period: 60 seconds

## Environment-Specific Configuration

### Development
- `launch_type`: FARGATE_SPOT (cost savings)
- `desired_count`: 1
- `task_cpu`: "256"
- `task_memory`: "512"
- `log_retention_days`: 7
- `enable_container_insights`: false

### Production
- `launch_type`: FARGATE (reliability)
- `desired_count`: 2-3 (high availability)
- `task_cpu`: "512" or higher
- `task_memory`: "1024" or higher
- `log_retention_days`: 90
- `enable_container_insights`: true

## Load Balancer Integration

Load balancer configuration is commented out and will be enabled when the ALB module is integrated. The service is prepared to accept target group ARN for ALB attachment.
