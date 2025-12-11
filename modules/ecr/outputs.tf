# ECR Module Outputs

output "repository_urls" {
  description = "Map of service names to ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.service : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of service names to ECR repository ARNs"
  value       = { for k, v in aws_ecr_repository.service : k => v.arn }
}

output "repository_names" {
  description = "Map of service names to ECR repository names"
  value       = { for k, v in aws_ecr_repository.service : k => v.name }
}

output "registry_id" {
  description = "ECR registry ID (same for all repositories)"
  value       = values(aws_ecr_repository.service)[0].registry_id
}
