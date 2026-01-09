# WAF Module Variables

variable "project_name" {
  description = "Name of the project (kebab-case)"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB to associate with WAF"
  type        = string
}
