# ECR Module
# Creates ECR repositories for container image storage (one per service)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ECR Repository (one per service)
resource "aws_ecr_repository" "service" {
  for_each = var.services

  name                 = "${var.project_name}-${var.environment}-${each.key}"
  image_tag_mutability = each.value.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = each.value.ecr_scan_on_push
  }

  encryption_configuration {
    encryption_type = each.value.ecr_encryption_type
    kms_key         = each.value.ecr_kms_key_arn
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-${each.key}-ecr"
    Service = each.key
  }
}

# Lifecycle Policy (one per service)
resource "aws_ecr_lifecycle_policy" "service" {
  for_each = var.services

  repository = aws_ecr_repository.service[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${each.value.ecr_max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = each.value.ecr_max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after ${each.value.ecr_untagged_image_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = each.value.ecr_untagged_image_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
