# ECS Module Variables

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
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "enable_container_insights" {
  description = "Enable container insights"
  type        = string

  validation {
    condition     = contains(["enabled", "disabled"], var.enable_container_insights)
    error_message = "Container insights must be enabled or disabled."
  }
}

# Network Configuration
variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

# IAM Configuration
variable "task_execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}

# ECR Configuration
variable "ecr_repository_urls" {
  description = "Map of service names to ECR repository URLs"
  type        = map(string)
}

# AWS Region
variable "aws_region" {
  description = "AWS region for CloudWatch logs configuration"
  type        = string
}

# Services Configuration
variable "services" {
  description = "Map of ECS service configurations"
  type = map(object({
    container_name      = string
    container_port      = number
    container_image_tag = string
    container_environment_variables = list(object({
      name  = string
      value = string
    }))
    task_cpu                           = string
    task_memory                        = string
    desired_count                      = number
    launch_type                        = string
    assign_public_ip                   = bool
    use_private_subnets                = bool
    log_retention_days                 = number
    health_check_command               = list(string)
    health_check_interval              = number
    health_check_timeout               = number
    health_check_retries               = number
    health_check_start_period          = number
    deployment_maximum_percent         = number
    deployment_minimum_healthy_percent = number
    enable_deployment_circuit_breaker  = bool
    enable_deployment_rollback         = bool
  }))
}
