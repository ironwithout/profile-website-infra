# WAF Module Variables

variable "project_name" {
  description = "Name of the project (kebab-case)"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB to associate with WAF"
  type        = string
}

variable "rate_limit_enabled" {
  description = "Enable rate limiting rule"
  type        = bool
  default     = true
}

variable "rate_limit_requests" {
  description = "Maximum number of requests per 5 minutes from a single IP"
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit_requests >= 100 && var.rate_limit_requests <= 20000000
    error_message = "Rate limit must be between 100 and 20,000,000 requests per 5 minutes."
  }
}

variable "ip_allowlist" {
  description = "List of IP addresses (CIDR format) to always allow (e.g., ['1.2.3.4/32'])"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ip in var.ip_allowlist : can(cidrhost(ip, 0))
    ])
    error_message = "All IP addresses must be in valid CIDR format (e.g., 1.2.3.4/32)."
  }
}
