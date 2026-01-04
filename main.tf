# Root Terraform configuration
# Orchestrates modules for ECS Fargate deployment

module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  ecr_repository_arns = var.ecr_repository_arns
}

module "alb" {
  count  = var.enable_alb ? 1 : 0
  source = "./modules/alb"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.network.vpc_id
  alb_security_group_id      = module.network.alb_security_group_id
  public_subnet_ids          = module.network.public_subnet_ids
  enable_deletion_protection = var.alb_deletion_protection

  services = {
    for name, config in var.ecs_services : name => {
      container_port                   = config.container_port
      health_check_healthy_threshold   = config.alb_health_check_healthy_threshold
      health_check_unhealthy_threshold = config.alb_health_check_unhealthy_threshold
      health_check_timeout             = config.health_check_timeout
      health_check_interval            = config.health_check_interval
      health_check_path                = config.alb_health_check_path
      health_check_matcher             = config.alb_health_check_matcher
      deregistration_delay             = config.alb_deregistration_delay
      listener_rule_priority           = config.alb_listener_rule_priority
      path_pattern                     = config.alb_path_pattern
      host_header                      = config.alb_host_header
    }
  }
}

module "ecs" {
  source = "./modules/ecs"

  project_name              = var.project_name
  environment               = var.environment
  enable_container_insights = var.enable_container_insights
  public_subnet_ids         = module.network.public_subnet_ids
  private_subnet_ids        = module.network.private_subnet_ids
  ecs_security_group_id     = module.network.ecs_security_group_id
  task_execution_role_arn   = module.iam.task_execution_role_arn
  task_role_arn             = module.iam.task_role_arn
  aws_region                = data.aws_region.current.name
  services                  = var.ecs_services
  alb_target_group_arns     = var.enable_alb ? module.alb[0].target_group_arns : {}
}
