# ECS Module Outputs

output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "service_ids" {
  description = "Map of service names to service IDs"
  value       = { for k, v in aws_ecs_service.service : k => v.id }
}

output "service_names" {
  description = "Map of service names to service names"
  value       = { for k, v in aws_ecs_service.service : k => v.name }
}

output "task_definition_arns" {
  description = "Map of service names to task definition ARNs"
  value       = { for k, v in aws_ecs_task_definition.service : k => v.arn }
}

output "task_definition_families" {
  description = "Map of service names to task definition families"
  value       = { for k, v in aws_ecs_task_definition.service : k => v.family }
}

output "log_group_names" {
  description = "Map of service names to CloudWatch log group names"
  value       = { for k, v in aws_cloudwatch_log_group.service : k => v.name }
}
