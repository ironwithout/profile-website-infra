variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for validation (prevents deploying to wrong account)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS account ID must be exactly 12 digits."
  }
}

variable "project_name" {
  description = "Project name used for resource naming (lowercase, hyphens)"
  type        = string
  default     = "profile-website"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase with hyphens only (kebab-case)."
  }
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be one of: dev, or prod."
  }
}

# Network
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ECR Configuration
variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs for IAM permissions"
  type        = list(string)
}

# ECS Cluster Configuration
variable "enable_container_insights" {
  description = "Enable container insights for ECS cluster"
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.enable_container_insights)
    error_message = "Container insights must be enabled or disabled."
  }
}

# ECS Services - Simplified with sensible defaults
variable "ecs_services" {
  description = "Map of ECS service configurations (minimal required fields, rest use sensible defaults)"
  type = map(object({
    # Required fields
    container_name  = string
    container_image = string
    container_port  = number

    # Optional with defaults
    container_image_tag       = optional(string, "latest")
    task_cpu                  = optional(string, "256")
    task_memory               = optional(string, "512")
    desired_count             = optional(number, 1)
    launch_type               = optional(string, "FARGATE")
    environment_variables     = optional(map(string), {})
    use_private_subnets       = optional(bool, null) # null = auto: private if ALB enabled, public otherwise
    assign_public_ip          = optional(bool, null) # null = auto: true for public subnets, false for private
    log_retention_days        = optional(number, 7)
    health_check_command      = optional(list(string), null)
    health_check_grace_period = optional(number, 60)
  }))

  default = {}
}

# ALB Configuration
variable "enable_alb" {
  description = "Enable Application Load Balancer"
  type        = bool
  default     = false
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

# ALB routing configuration (only used when enable_alb = true)
variable "alb_routes" {
  description = "ALB routing configuration per service (only required when enable_alb = true)"
  type = map(object({
    path_pattern          = string
    priority              = number
    host_header           = optional(string, null)
    health_check_path     = optional(string, "/health")
    health_check_matcher  = optional(string, "200-299")
    health_check_interval = optional(number, 30)
    health_check_timeout  = optional(number, 5)
    healthy_threshold     = optional(number, 2)
    unhealthy_threshold   = optional(number, 3)
    deregistration_delay  = optional(number, 30)
  }))
  default = {}

  validation {
    condition     = !var.enable_alb || length(var.alb_routes) > 0
    error_message = "When ALB is enabled, alb_routes must be configured for at least one service."
  }
}
