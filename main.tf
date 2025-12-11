# Root Terraform configuration
# Orchestrates modules for ECS Fargate deployment

module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "ecr" {
  source = "./modules/ecr"

  project_name         = var.project_name
  environment          = var.environment
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  encryption_type      = var.ecr_encryption_type
  kms_key_arn          = var.ecr_kms_key_arn
  max_image_count      = var.ecr_max_image_count
  untagged_image_days  = var.ecr_untagged_image_days
}

module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  ecr_repository_arns = [module.ecr.repository_arn]
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
  ecr_repository_url        = module.ecr.repository_url
  aws_region                = data.aws_region.current.name

  # Pass the entire services map to the module
  services = var.ecs_services
}
