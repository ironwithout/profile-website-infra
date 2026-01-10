# ACM Module

Creates SSL/TLS certificates for HTTPS using AWS Certificate Manager with DNS validation.

## Resources Created

- **ACM Certificate** with DNS validation method
- **Certificate Validation** resource (waits for validation to complete)

## DNS Validation

Since DNS is managed externally (e.g., Cloudflare), validation records must be created manually using the `domain_validation_options` output.

Example validation record:
```
Name:  _abc123.example.com
Type:  CNAME
Value: _xyz789.acm-validations.aws.
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | Project name (kebab-case) | `string` | Yes |
| `domain_name` | Primary domain name for the certificate | `string` | Yes |

## Outputs

| Name | Description |
|------|-------------|
| `certificate_arn` | ARN of the ACM certificate |
| `certificate_domain_name` | Domain name of the certificate |
| `certificate_status` | Status of the certificate |
| `domain_validation_options` | DNS validation records to create externally |
