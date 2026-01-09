# IAM Module
# Creates IAM roles for ECS tasks

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-execution"
  }
}

# ECR Access - Scoped to specific repositories
data "aws_iam_policy_document" "task_execution_ecr" {
  # GetAuthorizationToken must use "*" resource (account-level operation)
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  # Repository-specific pull permissions
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_policy" "task_execution_ecr" {
  name        = "${var.project_name}-ecs-task-execution-ecr"
  description = "Allow ECS task execution to pull images from specific ECR repositories"
  policy      = data.aws_iam_policy_document.task_execution_ecr.json

  tags = {
    Name = "${var.project_name}-ecs-task-execution-ecr"
  }
}

resource "aws_iam_role_policy_attachment" "task_execution_ecr" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution_ecr.arn
}

data "aws_iam_policy_document" "task_execution_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/ecs/${var.project_name}/*",
      "arn:aws:logs:*:*:log-group:/ecs/${var.project_name}/*:*"
    ]
  }
}

resource "aws_iam_policy" "task_execution_logs" {
  name        = "${var.project_name}-ecs-task-execution-logs"
  description = "Allow ECS task execution to write logs to CloudWatch"
  policy      = data.aws_iam_policy_document.task_execution_logs.json

  tags = {
    Name = "${var.project_name}-ecs-task-execution-logs"
  }
}

resource "aws_iam_role_policy_attachment" "task_execution_logs" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution_logs.arn
}

resource "aws_iam_role" "task" {
  name = "${var.project_name}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-task"
  }
}
