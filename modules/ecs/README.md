# ECS Module

Creates an ECS Fargate cluster with task definitions and services for running containerized applications.

## Resources Created

- **ECS Cluster** with Container Insights enabled
- **CloudWatch Log Groups** (one per service)
- **Task Definitions** (Fargate, awsvpc network mode)
- **ECS Services** with circuit breaker and ALB integration

## Deployment Strategy

- **Maximum percent**: 200% (allows new tasks before terminating old)
- **Minimum healthy**: 100% (maintains capacity during deployment)
- **Circuit breaker**: Enabled with automatic rollback on failure

## Network Configuration

Tasks run in `awsvpc` mode with:
- Public IP assignment (for public subnets without NAT)
- Security group from network module
- ALB target group registration

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | Project name (kebab-case) | `string` | Yes |
| `subnet_ids` | List of subnet IDs for tasks | `list(string)` | Yes |
| `ecs_security_group_id` | Security group ID for tasks | `string` | Yes |
| `task_execution_role_arn` | ARN of task execution role | `string` | Yes |
| `task_role_arn` | ARN of task role | `string` | Yes |
| `aws_region` | AWS region for CloudWatch logs | `string` | Yes |
| `service_images` | Map of service name to container image | `map(string)` | Yes |
| `services` | Map of service configurations | `map(object)` | Yes |
| `alb_target_group_arns` | Map of service name to target group ARN | `map(string)` | Yes |

### Service Configuration Object

```hcl
services = {
  web = {
    container_name            = "web"
    container_port            = 80
    task_cpu                  = "256"
    task_memory               = "512"
    desired_count             = 1
    launch_type               = "FARGATE"
    log_retention_days        = 7
    environment_variables     = { ENV = "prod" }
    health_check_command      = ["CMD-SHELL", "curl -f http://localhost || exit 1"]
    health_check_grace_period = 60
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | ECS cluster name |
| `cluster_arn` | ECS cluster ARN |
| `service_names` | Map of service names |
| `service_ids` | Map of service IDs |
| `task_definition_arns` | Map of task definition ARNs |
| `task_definition_families` | Map of task definition families |
| `log_group_names` | Map of CloudWatch log group names |
