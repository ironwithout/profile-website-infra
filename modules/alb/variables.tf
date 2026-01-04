# ALB Module Variables

variable "project_name" {
  description = "Project name for resource naming (kebab-case only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.project_name))
    error_message = "Project name must be kebab-case (lowercase letters, numbers, and hyphens only)."
  }
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment must be dev, prod, or staging."
  }
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB (managed by network module)"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnets required for ALB (multi-AZ)."
  }
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "services" {
  description = "Map of service configurations for ALB target groups"
  type = map(object({
    container_port                   = number
    health_check_healthy_threshold   = number
    health_check_unhealthy_threshold = number
    health_check_timeout             = number
    health_check_interval            = number
    health_check_path                = string
    health_check_matcher             = string
    deregistration_delay             = number
    listener_rule_priority           = number
    path_pattern                     = string
    host_header                      = string
  }))
}
