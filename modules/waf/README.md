# WAF Module

Web Application Firewall (WAF) module for protecting your ALB from common web exploits.

## Overview

Creates an AWS WAFv2 Web ACL with managed rule groups and optional custom rules for rate limiting and IP filtering.

## Features

- **AWS Managed Core Rule Set**: Protection against OWASP Top 10 vulnerabilities
- **Known Bad Inputs**: Blocks malformed requests
- **IP Reputation List**: Blocks IPs with known malicious activity
- **Rate Limiting**: Configurable per-IP request rate limiting
- **IP Allowlist**: Optional allowlist for trusted IPs
- **CloudWatch Metrics**: Full visibility into blocked/allowed requests

## Usage

```hcl
module "waf" {
  count  = var.enable_waf ? 1 : 0
  source = "./modules/waf"

  project_name    = var.project_name
  environment     = var.environment
  alb_arn         = module.alb[0].alb_arn

  # Optional: Rate limiting
  rate_limit_enabled  = true
  rate_limit_requests = 2000  # per 5 minutes per IP

  # Optional: IP allowlist
  ip_allowlist = ["1.2.3.4/32"]  # Your office IP
}
```

## Managed Rules

### 1. AWSManagedRulesCommonRuleSet
Protects against common threats:
- SQL injection
- Cross-site scripting (XSS)
- Local file inclusion (LFI)
- Remote file inclusion (RFI)

### 2. AWSManagedRulesKnownBadInputsRuleSet
Blocks requests with invalid or malformed patterns:
- Invalid headers
- Malformed URIs
- Bad query strings

### 3. AWSManagedRulesAmazonIpReputationList
Blocks requests from IPs known for:
- Botnet activity
- Scanning/probing
- Malicious activity

### 4. Rate Limiting (Optional)
Prevents abuse by limiting requests per IP:
- Default: 2000 requests per 5 minutes
- Configurable threshold
- Per-IP tracking

### 5. IP Allowlist (Optional)
Always allow specific IPs:
- Office IPs
- CI/CD systems
- Monitoring services

## Monitoring

View WAF metrics in CloudWatch:
- Allowed/blocked requests
- Per-rule metrics
- Sampled requests for debugging

Navigate to: **CloudWatch → Metrics → WAFV2**

## Cost

- **WebACL**: $5/month
- **Rules**: $1/month per rule (3-4 rules = $3-4)
- **Requests**: $0.60 per million requests
- **Total**: ~$12-20/month (depending on traffic)

## Important Notes

- **False Positives**: Managed rules may occasionally block legitimate traffic
- **Testing**: Test in dev environment first
- **Tuning**: Monitor CloudWatch metrics and adjust rules if needed
- **Regional**: WAF must be in same region as ALB
