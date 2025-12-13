# ALB Module
# Creates Application Load Balancer for distributing traffic to ECS services

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

##################################################
# Application Load Balancer
##################################################

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

##################################################
# Target Groups (one per service)
##################################################

resource "aws_lb_target_group" "service" {
  for_each = var.services

  name        = "${var.project_name}-${var.environment}-${each.key}-tg"
  port        = each.value.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Required for Fargate

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = each.value.health_check_healthy_threshold
    unhealthy_threshold = each.value.health_check_unhealthy_threshold
    timeout             = each.value.health_check_timeout
    interval            = each.value.health_check_interval
    path                = each.value.health_check_path
    matcher             = each.value.health_check_matcher
    protocol            = "HTTP"
  }

  # Deregistration delay
  deregistration_delay = each.value.deregistration_delay

  tags = {
    Name    = "${var.project_name}-${var.environment}-${each.key}-tg"
    Service = each.key
  }

  lifecycle {
    create_before_destroy = true
  }
}

##################################################
# ALB Listener (HTTP)
##################################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default action - can be customized per deployment
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service not found"
      status_code  = "404"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-http-listener"
  }
}

##################################################
# Listener Rules (route traffic to services)
##################################################

resource "aws_lb_listener_rule" "service" {
  for_each = var.services

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  # Route based on path pattern or host header
  dynamic "condition" {
    for_each = each.value.path_pattern != null ? [1] : []
    content {
      path_pattern {
        values = [each.value.path_pattern]
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.host_header != null ? [1] : []
    content {
      host_header {
        values = [each.value.host_header]
      }
    }
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-${each.key}-rule"
    Service = each.key
  }
}
