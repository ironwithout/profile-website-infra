# ECR Module Variables

variable "project_name" {
  description = "Project name for resource naming (kebab-case only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.project_name))
    error_message = "Project name must be kebab-case (lowercase letters, numbers, and hyphens only)."
  }
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev, or prod."
  }
}

variable "services" {
  description = "Map of service configurations for ECR repositories"
  type = map(object({
    ecr_image_tag_mutability = string
    ecr_scan_on_push         = bool
    ecr_encryption_type      = string
    ecr_kms_key_arn          = string
    ecr_max_image_count      = number
    ecr_untagged_image_days  = number
  }))
}
