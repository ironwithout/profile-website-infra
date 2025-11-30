# Network Module

## Overview
This module creates the VPC infrastructure for ECS Fargate deployment, including VPC, subnets, internet gateway, route tables, and security groups.

## Architecture
- **VPC**: Configurable CIDR block with DNS support enabled
- **Public Subnets**: Internet-facing subnets for ALB (auto-assign public IP)
- **Private Subnets**: Internal subnets for ECS tasks (optional, can use public for cost savings)
- **Internet Gateway**: Provides internet access to public subnets
- **Security Groups**: 
  - ALB Security Group: Allows HTTP/HTTPS from internet
  - ECS Security Group: Allows traffic from ALB using source-based referencing

## Usage
```hcl
module "network" {
  source = "./modules/network"

  project_name       = "myapp"
  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
}
```

## Inputs
| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_name | Project name for resource naming | string | yes |
| environment | Environment (dev/prod/staging) | string | yes |
| vpc_cidr | CIDR block for VPC | string | yes |
| availability_zones | List of AZs for subnet distribution | list(string) | yes |

## Outputs
| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| alb_security_group_id | ALB security group ID |
| ecs_security_group_id | ECS security group ID |
| internet_gateway_id | Internet Gateway ID |

## Security Pattern
Uses **source-based security group referencing** instead of CIDR blocks for internal traffic (ALB → ECS), following AWS best practices.

## Cost Optimization
Public subnets with auto-assign public IP enabled to avoid NAT Gateway costs for dev/staging environments.
