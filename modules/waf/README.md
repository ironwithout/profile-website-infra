# WAF Module

Creates a Web Application Firewall to protect the ALB using AWS Managed Rules.

## Resources Created

- **WAF Web ACL** (regional scope for ALB)
- **ALB Association**

## Rules

| Priority | Rule | Action | Description |
|----------|------|--------|-------------|
| 1 | AWSManagedRulesCommonRuleSet | Block | OWASP Top 10 protection |
| 2 | AWSManagedRulesKnownBadInputsRuleSet | Block | Known malicious patterns |
| 3 | AWSManagedRulesAmazonIpReputationList | Block | IPs with poor reputation |
| 4 | RateLimitRule | Block | 2000 requests/5min per IP |

Default action is **allow** - only matched threats are blocked.

## CloudWatch Metrics

All rules have CloudWatch metrics enabled:
- `{project_name}-common-rules`
- `{project_name}-bad-inputs`
- `{project_name}-ip-reputation`
- `{project_name}-rate-limit`
- `{project_name}-waf` (overall)

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | Project name (kebab-case) | `string` | Yes |
| `alb_arn` | ARN of the ALB to protect | `string` | Yes |

## Outputs

| Name | Description |
|------|-------------|
| `web_acl_id` | ID of the WAF Web ACL |
| `web_acl_arn` | ARN of the WAF Web ACL |
| `web_acl_name` | Name of the WAF Web ACL |
| `web_acl_capacity` | Web ACL capacity units used |
