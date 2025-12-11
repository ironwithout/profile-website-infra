# Root outputs for cross-module references

# Network outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.network.private_subnet_ids
}

# ECR outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs for docker push/pull"
  value       = module.ecr.repository_urls
}

output "ecr_repository_names" {
  description = "ECR repository names"
  value       = module.ecr.repository_names
}

# IAM outputs
output "iam_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.iam.task_execution_role_arn
}

output "iam_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.iam.task_role_arn
}
