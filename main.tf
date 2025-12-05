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
