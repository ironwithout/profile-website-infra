# Root Terraform configuration
# Orchestrates modules for ECS Fargate deployment

module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  ecr_repository_arns = var.ecr_repository_arns
}

module "acm" {
  source = "./modules/acm"

  project_name = var.project_name
  domain_name  = var.domain_name
}

module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  vpc_id                = module.network.vpc_id
  alb_security_group_id = module.network.alb_security_group_id
  public_subnet_ids     = module.network.public_subnet_ids
  certificate_arn       = module.acm.certificate_arn

  services = {
    for name, route_config in var.alb_routes : name => {
      container_port         = var.ecs_services[name].container_port
      health_check_path      = route_config.health_check_path
      health_check_matcher   = route_config.health_check_matcher
      health_check_interval  = route_config.health_check_interval
      health_check_timeout   = route_config.health_check_timeout
      healthy_threshold      = route_config.healthy_threshold
      unhealthy_threshold    = route_config.unhealthy_threshold
      deregistration_delay   = route_config.deregistration_delay
      listener_rule_priority = route_config.priority
      path_pattern           = route_config.path_pattern
      host_header            = route_config.host_header
    }
  }
}

module "waf" {
  source = "./modules/waf"

  project_name = var.project_name
  alb_arn      = module.alb.alb_arn

  rate_limit_enabled  = true
  rate_limit_requests = var.waf_rate_limit
  ip_allowlist        = var.waf_ip_allowlist
}

module "ecs" {
  source = "./modules/ecs"

  project_name            = var.project_name
  public_subnet_ids       = module.network.public_subnet_ids
  private_subnet_ids      = module.network.private_subnet_ids
  ecs_security_group_id   = module.network.ecs_security_group_id
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn
  aws_region              = data.aws_region.current.name

  # Pass simplified services with computed defaults
  services = {
    for name, config in var.ecs_services : name => {
      container_name            = config.container_name
      container_port            = config.container_port
      container_image           = config.container_image
      container_image_tag       = config.container_image_tag
      task_cpu                  = config.task_cpu
      task_memory               = config.task_memory
      desired_count             = config.desired_count
      launch_type               = config.launch_type
      log_retention_days        = config.log_retention_days
      environment_variables     = config.environment_variables
      health_check_command      = config.health_check_command
      health_check_grace_period = config.health_check_grace_period
      enable_execute_command    = config.enable_execute_command

      use_private_subnets = config.use_private_subnets
      assign_public_ip    = config.assign_public_ip
    }
  }

  alb_target_group_arns = module.alb.target_group_arns
}
