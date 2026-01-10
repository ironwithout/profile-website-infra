# IAM Module

Creates IAM roles for ECS task execution and application tasks with least-privilege permissions.

## Resources Created

- **Task Execution Role** - Used by ECS to pull images and write logs
- **Task Role** - Used by the application container for AWS API calls
- **ECR Policy** - Scoped to specific ECR repositories
- **CloudWatch Logs Policy** - Scoped to `/ecs/${project_name}/*` log groups

## Role Permissions

| Role | Permissions |
|------|-------------|
| Task Execution | `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`, `logs:CreateLogStream`, `logs:PutLogEvents` |
| Task | None by default (add as needed for application) |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | Project name (kebab-case) | `string` | Yes |
| `ecr_repository_arns` | List of ECR repository ARNs that ECS can pull from | `list(string)` | Yes |

## Outputs

| Name | Description |
|------|-------------|
| `task_execution_role_arn` | ARN of the task execution role |
| `task_execution_role_name` | Name of the task execution role |
| `task_role_arn` | ARN of the task role |
| `task_role_name` | Name of the task role |
