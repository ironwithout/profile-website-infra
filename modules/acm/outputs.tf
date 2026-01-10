# ACM Module Outputs

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.main.arn
  sensitive   = true
}

output "certificate_domain_name" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Status of the certificate"
  value       = aws_acm_certificate.main.status
}

output "validation_instructions" {
  description = "Instructions for manual DNS validation"
  value       = <<-EOT
    ⚠️  MANUAL ACTION REQUIRED: Add these DNS records
    1. Add a CNAME record:
       - Type: CNAME
       - Name: (use CNAME name from AWS certificate resource)
       - Target: (use CNAME value from AWS certificate resource)
       - TTL: Auto
       - Proxy: DNS only

    2. Wait 5-10 minutes for DNS propagation
    3. Certificate will automatically validate once DNS records are detected
  EOT
}
