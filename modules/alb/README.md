# ALB Module

Creates an Application Load Balancer (ALB) with target groups for ECS Fargate services.

## Features

- Application Load Balancer in public subnets
- Target groups per service (IP target type for Fargate)
- HTTP listener with path-based or host-based routing
- Health checks with configurable thresholds
- Security group allowing HTTP/HTTPS from internet

## Resources Created

- `aws_lb` - Application Load Balancer
- `aws_lb_target_group` - One per service
- `aws_lb_listener` - HTTP listener (port 80)
- `aws_lb_listener_rule` - Routing rules per service
- `aws_security_group` - ALB security group

## Usage

```hcl
module "alb" {
  source = "./modules/alb"

  project_name       = "myapp"
  environment        = "dev"
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids

  services = {
    nginx = {
      container_port                   = 80
      health_check_healthy_threshold   = 2
      health_check_unhealthy_threshold = 3
      health_check_timeout             = 5
      health_check_interval            = 30
      health_check_path                = "/"
      health_check_matcher             = "200-299"
      deregistration_delay             = 30
      listener_rule_priority           = 100
      path_pattern                     = "/*"
      host_header                      = null
    }
  }
}
```

## Integration with ECS Module

The ALB target group ARNs must be passed to the ECS module:

```hcl
module "ecs" {
  source = "./modules/ecs"
  
  # ... other variables ...
  
  alb_target_group_arns = module.alb.target_group_arns
}
```

The ECS service resource needs to register with the target group:

```hcl
resource "aws_ecs_service" "service" {
  # ... other config ...
  
  load_balancer {
    target_group_arn = var.alb_target_group_arns[each.key]
    container_name   = each.value.container_name
    container_port   = each.value.container_port
  }
}
```

## Routing Configuration

### Path-based routing
Route traffic based on URL path:

```hcl
services = {
  api = {
    path_pattern = "/api/*"
    host_header  = null
    # ...
  }
}
```

### Host-based routing
Route traffic based on domain:

```hcl
services = {
  web = {
    path_pattern = null
    host_header  = "example.com"
    # ...
  }
}
```

## Health Checks

Target group health checks verify container health:

- `health_check_path` - Path to check (e.g., `/health`)
- `health_check_interval` - Seconds between checks (default: 30)
- `health_check_timeout` - Timeout in seconds (default: 5)
- `health_check_healthy_threshold` - Consecutive successes to mark healthy (default: 2)
- `health_check_unhealthy_threshold` - Consecutive failures to mark unhealthy (default: 3)
- `health_check_matcher` - HTTP status codes considered healthy (default: "200-299")

## Outputs

| Output | Description |
|--------|-------------|
| `alb_dns_name` | ALB DNS name for accessing services |
| `alb_arn` | ALB ARN |
| `alb_zone_id` | Zone ID for Route53 alias records |
| `target_group_arns` | Map of service name to target group ARN |
| `alb_security_group_id` | Security group ID of ALB |

## Security

- ALB accepts traffic from internet (0.0.0.0/0) on ports 80/443
- ECS security group should only allow traffic from ALB security group
- Remove direct internet access to ECS tasks when using ALB

## HTTPS Support

To add HTTPS:

1. Create ACM certificate
2. Add HTTPS listener:
```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["web"].arn
  }
}
```

3. Add HTTP to HTTPS redirect

## IAM Permissions

The terraform-deployer user needs permissions to manage ELB resources. Apply the policy:

```bash
POLICY_ARN=$(aws iam list-policies --scope Local \
  --query 'Policies[?PolicyName==`terraform-deployer-alb`].Arn' \
  --output text)

aws iam create-policy-version \
  --policy-arn $POLICY_ARN \
  --policy-document file://modules/alb/iam-policy.json \
  --set-as-default
```

## Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `project_name` | string | yes | - | Project name (kebab-case) |
| `environment` | string | yes | - | Environment (dev/prod/staging) |
| `vpc_id` | string | yes | - | VPC ID |
| `public_subnet_ids` | list(string) | yes | - | Public subnet IDs (min 2) |
| `enable_deletion_protection` | bool | no | false | Enable deletion protection |
| `services` | map(object) | yes | - | Service configurations |

## Service Configuration

Each service in the `services` map requires:

```hcl
{
  container_port                   = number  # Container port
  health_check_healthy_threshold   = number  # Consecutive successes
  health_check_unhealthy_threshold = number  # Consecutive failures
  health_check_timeout             = number  # Timeout in seconds
  health_check_interval            = number  # Check interval in seconds
  health_check_path                = string  # Health check path
  health_check_matcher             = string  # Success status codes
  deregistration_delay             = number  # Draining time in seconds
  listener_rule_priority           = number  # Rule priority (unique)
  path_pattern                     = string  # Path pattern or null
  host_header                      = string  # Host header or null
}
```

## Migration from Direct Access

When migrating from direct container access to ALB:

1. Deploy ALB module
2. Update ECS service to register with target group
3. Update ECS configuration:
   - Set `assign_public_ip = false`
   - Set `use_private_subnets = true`
4. Remove `internet_to_ecs` security group rule
5. Access via ALB DNS name instead of container IP
