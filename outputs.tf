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

# ACM outputs (conditional)
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.enable_alb && var.domain_name != "" ? module.acm[0].certificate_arn : null
}

output "acm_certificate_status" {
  description = "Status of the ACM certificate"
  value       = var.enable_alb && var.domain_name != "" ? module.acm[0].certificate_status : null
}

output "acm_validation_records" {
  description = "DNS validation records to add in Cloudflare (IMPORTANT: Add these to validate certificate)"
  value       = var.enable_alb && var.domain_name != "" ? module.acm[0].domain_validation_options : []
}

output "acm_validation_instructions" {
  description = "Instructions for validating certificate in Cloudflare"
  value       = var.enable_alb && var.domain_name != "" ? module.acm[0].validation_instructions : ""
}

# WAF outputs (conditional)
output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.enable_alb && var.enable_waf ? module.waf[0].web_acl_arn : null
}

output "waf_web_acl_name" {
  description = "Name of the WAF Web ACL"
  value       = var.enable_alb && var.enable_waf ? module.waf[0].web_acl_name : null
}
