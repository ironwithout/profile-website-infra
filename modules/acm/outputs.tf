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

output "domain_validation_options" {
  description = "DNS validation records to create in Cloudflare"
  value = [
    for dvo in aws_acm_certificate.main.domain_validation_options : {
      domain_name           = dvo.domain_name
      resource_record_name  = dvo.resource_record_name
      resource_record_type  = dvo.resource_record_type
      resource_record_value = dvo.resource_record_value
    }
  ]
}

output "validation_instructions" {
  description = "Instructions for manual DNS validation in Cloudflare"
  value       = <<-EOT
    ⚠️  MANUAL ACTION REQUIRED: Add these DNS records in Cloudflare
    
    For each domain validation option above:
    1. Log into Cloudflare DNS management
    2. Add a CNAME record:
       - Type: CNAME
       - Name: ${join(", ", [for dvo in aws_acm_certificate.main.domain_validation_options : dvo.resource_record_name])}
       - Target: (use resource_record_value from domain_validation_options output)
       - TTL: Auto
       - Proxy: DNS only (orange cloud OFF)
    
    3. Wait 5-10 minutes for DNS propagation
    4. Certificate will automatically validate once DNS records are detected
  EOT
}
