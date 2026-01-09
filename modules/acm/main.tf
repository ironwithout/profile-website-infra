# ACM Module
# Manages SSL/TLS certificates for HTTPS

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

##################################################
# ACM Certificate
##################################################

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name   = "${var.project_name}-cert"
    Domain = var.domain_name
  }
}

##################################################
# Certificate Validation (outputs only)
##################################################

# Note: Since DNS is managed by Cloudflare, validation records
# must be created manually in Cloudflare using the outputs.
# Terraform will wait for validation to complete.

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn

  # Manual validation - no validation_record_fqdns needed
  # User must create DNS records in Cloudflare first

  timeouts {
    create = "45m"
  }
}
