# IAM Module Outputs

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role (used by ECS to pull images and write logs)"
  value       = aws_iam_role.task_execution.arn
}

output "task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.task_execution.name
}

output "task_role_arn" {
  description = "ARN of the ECS task role (used by application container for AWS API calls)"
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.task.name
}
