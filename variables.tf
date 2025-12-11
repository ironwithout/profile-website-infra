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

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase with hyphens only (kebab-case)."
  }
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment must be one of: dev, prod, staging."
  }
}

# Network
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# ECR
variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability (MUTABLE or IMMUTABLE)"
  type        = string
}

variable "ecr_scan_on_push" {
  description = "Enable ECR image scanning on push"
  type        = bool
}

variable "ecr_encryption_type" {
  description = "ECR encryption type (AES256 or KMS)"
  type        = string
}

variable "ecr_kms_key_arn" {
  description = "KMS key ARN for encryption (required if encryption_type is KMS)"
  type        = string
}

variable "ecr_max_image_count" {
  description = "Maximum number of tagged ECR images to retain"
  type        = number
}

variable "ecr_untagged_image_days" {
  description = "Days to retain untagged ECR images before expiration"
  type        = number
}

# ECS configuration
variable "enable_container_insights" {
  description = "Enable container insights"
  type        = string

  validation {
    condition     = contains(["enabled", "disabled"], var.enable_container_insights)
    error_message = "Container insights must be enabled or disabled."
  }
}

variable "ecs_services" {
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
    enable_container_insights          = bool
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

  default = {}
}
