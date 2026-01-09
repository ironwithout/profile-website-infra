# ACM Module

Manages SSL/TLS certificates for HTTPS using AWS Certificate Manager (ACM).

## Overview

This module creates an ACM certificate with DNS validation. Since DNS is managed by Cloudflare (not Route 53), validation records must be created manually in Cloudflare.

## Features

- SSL/TLS certificate with DNS validation
- Support for www subdomain as Subject Alternative Name (SAN)
- Outputs validation records for manual Cloudflare setup
- Automatic certificate renewal (once validated)

## Usage

```hcl
module "acm" {
  source = "./modules/acm"

  project_name = var.project_name
  domain_name  = "example.com"
  include_www  = true  # Adds www.example.com
}
```

## DNS Validation Workflow

1. **Apply Terraform**: Creates certificate request
2. **Check Outputs**: `terraform output` shows validation records
3. **Add to Cloudflare**:
   - Log into Cloudflare DNS
   - Add CNAME record(s) with values from output
   - **IMPORTANT**: Disable proxy (orange cloud OFF) - must be "DNS only"
4. **Wait**: Certificate validates automatically in 5-30 minutes
5. **Verify**: Check `certificate_status` output

## Important Notes

- **First-time setup**: Certificate validation can take up to 30 minutes
- **Cloudflare proxy**: Must be disabled for validation CNAME records
- **Automatic renewal**: Once validated, AWS handles renewal automatically
- **Multi-domain**: Both apex and www domains validated with same certificate

## Outputs

- `certificate_arn`: Use this for ALB HTTPS listener
- `domain_validation_options`: DNS records to add in Cloudflare
- `validation_instructions`: Step-by-step guide

## Cost

**$0/month** - ACM public certificates are free
