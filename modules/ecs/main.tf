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
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# CloudWatch Log Group for each service
resource "aws_cloudwatch_log_group" "service" {
  for_each = var.services

  name              = "/ecs/${var.project_name}/${each.key}"
  retention_in_days = each.value.log_retention_days

  tags = {
    Name    = "${var.project_name}-${each.key}-logs"
    Service = each.key
  }
}

# ECS Task Definition for each service
resource "aws_ecs_task_definition" "service" {
  for_each = var.services

  family                   = "${var.project_name}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.task_cpu
  memory                   = each.value.task_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = each.value.container_name
      image     = "${each.value.container_image}:${each.value.container_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = each.value.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for key, value in each.value.environment_variables : {
          name  = key
          value = value
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service[each.key].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = each.value.health_check_command != null ? {
        command     = each.value.health_check_command
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      } : null
    }
  ])

  tags = {
    Name    = "${var.project_name}-${each.key}-task"
    Service = each.key
  }
}

# ECS Service for each service
resource "aws_ecs_service" "service" {
  for_each = var.services

  name            = "${var.project_name}-${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = each.value.launch_type

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = lookup(var.alb_target_group_arns, each.key, null) != null ? each.value.health_check_grace_period : null

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
    Name    = "${var.project_name}-${each.key}-service"
    Service = each.key
  }
}
