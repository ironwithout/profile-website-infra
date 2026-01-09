# ALB Module Outputs

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
  sensitive   = true
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer (for Route53)"
  value       = aws_lb.main.zone_id
}

output "target_group_arns" {
  description = "Map of service names to target group ARNs"
  value       = { for k, v in aws_lb_target_group.service : k => v.arn }
  sensitive   = true
}

output "target_group_names" {
  description = "Map of service names to target group names"
  value       = { for k, v in aws_lb_target_group.service : k => v.name }
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http_redirect[0].arn
  sensitive   = true
}
