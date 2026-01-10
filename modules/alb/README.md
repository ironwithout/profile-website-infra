# ALB Module

Creates an Application Load Balancer with HTTPS support and path-based routing to ECS services.

## Resources Created

- **Application Load Balancer** (internet-facing, cross-zone enabled)
- **Target Groups** (one per service, IP target type for Fargate)
- **HTTPS Listener** (TLS 1.3, returns 404 by default)
- **HTTP Listener** (redirects to HTTPS)
- **Listener Rules** (routes traffic based on path/host patterns)

## Routing Configuration

Each service can be routed by:
- **Path pattern** (e.g., `/api/*`)
- **Host header** (e.g., `api.example.com`)
- Both combined

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | Project name (kebab-case) | `string` | Yes |
| `vpc_id` | VPC ID | `string` | Yes |
| `alb_security_group_id` | Security group ID for ALB | `string` | Yes |
| `public_subnet_ids` | List of public subnet IDs (min 2 for multi-AZ) | `list(string)` | Yes |
| `certificate_arn` | ARN of ACM certificate for HTTPS | `string` | Yes |
| `services` | Map of service routing configurations | `map(object)` | Yes |

### Service Configuration Object

```hcl
services = {
  web = {
    container_port         = 80
    health_check_path      = "/health"
    health_check_matcher   = "200-299"
    health_check_interval  = 30
    health_check_timeout   = 5
    healthy_threshold      = 2
    unhealthy_threshold    = 3
    deregistration_delay   = 30
    listener_rule_priority = 100
    path_pattern           = "/*"
    host_header            = "example.com"  # optional
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `alb_arn` | ARN of the ALB |
| `alb_dns_name` | DNS name of the ALB |
| `alb_zone_id` | Zone ID for Route53 alias records |
| `target_group_arns` | Map of service names to target group ARNs |
| `target_group_names` | Map of service names to target group names |
