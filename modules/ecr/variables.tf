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
  description = "Environment name (dev, prod, staging)"
  type        = string

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment must be dev, prod, or staging."
  }
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
}

variable "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  type        = string

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (required if encryption_type is KMS)"
  type        = string
}

variable "max_image_count" {
  description = "Maximum number of tagged images to retain"
  type        = number

  validation {
    condition     = var.max_image_count > 0
    error_message = "Max image count must be greater than 0."
  }
}

variable "untagged_image_days" {
  description = "Days to retain untagged images before expiration"
  type        = number

  validation {
    condition     = var.untagged_image_days > 0
    error_message = "Untagged image days must be greater than 0."
  }
}
