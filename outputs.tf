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

# IAM outputs
output "iam_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.iam.task_execution_role_arn
}

output "iam_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.iam.task_role_arn
}

# ECS outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_names" {
  description = "Map of service names"
  value       = module.ecs.service_names
}

# ALB outputs (conditional)
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (use this to access services)"
  value       = var.enable_alb ? module.alb[0].alb_dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID of the ALB for Route53"
  value       = var.enable_alb ? module.alb[0].alb_zone_id : null
}
