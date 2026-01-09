# ACM Module Variables

variable "project_name" {
  description = "Name of the project (kebab-case)"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for the certificate (e.g., example.com)"
  type        = string
}
