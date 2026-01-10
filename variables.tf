variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
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

# ECS Services Specs
variable "ecs_services" {
  description = "Map of ECS service configurations (minimal required fields, rest use sensible defaults)"
  type = map(object({
    # Required fields
    container_name = string
    container_port = number

    # Optional with defaults
    task_cpu                  = optional(string, "256")
    task_memory               = optional(string, "512")
    desired_count             = optional(number, 1)
    launch_type               = optional(string, "FARGATE")
    environment_variables     = optional(map(string), {})
    log_retention_days        = optional(number, 7)
    health_check_command      = optional(list(string), null)
    health_check_grace_period = optional(number, 60)
  }))
  default = {
    web = {
      container_name       = "web"
      container_port       = 80
      task_cpu             = "256"
      task_memory          = "512"
      health_check_command = ["CMD-SHELL", "curl -f http://localhost:80 || exit 1"]
    }
  }
}

# HTTPS/TLS Configuration
variable "domain_name" {
  description = "Primary domain name for SSL certificate (e.g., example.com). Leave empty to disable HTTPS."
  type        = string
  default     = "msdeleyto.es"
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
  default = {
    web = {
      path_pattern      = "/*"
      priority          = 100
      host_header       = "msdeleyto.es"
      health_check_path = "/"
    }
  }
}
