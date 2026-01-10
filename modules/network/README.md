# Network Module

Creates the VPC, subnets, internet gateway, and security groups for ECS Fargate infrastructure.

## Resources Created

- **VPC** with DNS support enabled
- **Public subnets** (one per AZ) with auto-assign public IP
- **Private subnets** (one per AZ) for future use
- **Internet Gateway** with route table for public subnets
- **Security Groups** for ALB and ECS tasks

## Security Group Configuration

| Security Group | Inbound | Outbound |
|----------------|---------|----------|
| ALB | 80, 443 from 0.0.0.0/0 | All traffic |
| ECS | 80 from ALB SG only | All traffic |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | Project name for resource naming | `string` | Yes |
| `vpc_cidr` | CIDR block for VPC | `string` | Yes |
| `availability_zones` | List of AZs for subnet distribution | `list(string)` | Yes |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `alb_security_group_id` | Security group ID for ALB |
| `ecs_security_group_id` | Security group ID for ECS tasks |
| `internet_gateway_id` | Internet Gateway ID |
