# ECS Module - Defines ECS Cluster, Task Definition, and Service

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ECS Cluster (shared by all services)
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# CloudWatch Log Group for each service
resource "aws_cloudwatch_log_group" "service" {
  for_each = var.services

  name              = "/ecs/${var.project_name}-${var.environment}/${each.key}"
  retention_in_days = each.value.log_retention_days

  tags = {
    Name    = "${var.project_name}-${var.environment}-${each.key}-logs"
    Service = each.key
  }
}

locals {
  service_images = {
    for name, config in var.services : name => (
      # If tag contains :// or starts with public domain, use as-is (full URL)
      can(regex("^(public\\.ecr\\.aws|[^:]+://)", config.container_image_tag))
      ? config.container_image_tag
      # Otherwise, prepend ECR repository URL
      : "${var.ecr_repository_urls[name]}:${config.container_image_tag}"
    )
  }
}

# ECS Task Definition for each service
resource "aws_ecs_task_definition" "service" {
  for_each = var.services

  family                   = "${var.project_name}-${var.environment}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.task_cpu
  memory                   = each.value.task_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = each.value.container_name
      image     = local.service_images[each.key]
      essential = true

      portMappings = [
        {
          containerPort = each.value.container_port
          protocol      = "tcp"
        }
      ]

      environment = each.value.container_environment_variables

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service[each.key].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = each.value.health_check_command
        interval    = each.value.health_check_interval
        timeout     = each.value.health_check_timeout
        retries     = each.value.health_check_retries
        startPeriod = each.value.health_check_start_period
      }
    }
  ])

  tags = {
    Name    = "${var.project_name}-${var.environment}-${each.key}-task"
    Service = each.key
  }
}

# ECS Service for each service
resource "aws_ecs_service" "service" {
  for_each = var.services

  name            = "${var.project_name}-${var.environment}-${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = each.value.launch_type

  network_configuration {
    subnets          = each.value.use_private_subnets ? var.private_subnet_ids : var.public_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = each.value.assign_public_ip
  }

  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent

  deployment_circuit_breaker {
    enable   = each.value.enable_deployment_circuit_breaker
    rollback = each.value.enable_deployment_rollback
  }

  # Register with ALB target group if ALB is enabled
  dynamic "load_balancer" {
    for_each = lookup(var.alb_target_group_arns, each.key, null) != null ? [1] : []
    content {
      target_group_arn = var.alb_target_group_arns[each.key]
      container_name   = each.value.container_name
      container_port   = each.value.container_port
    }
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-${each.key}-service"
    Service = each.key
  }
}
