locals {
  prefix = "${var.name}-${var.environment}-task-frontend"
}

# give ECS tasks ability to assume roles
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.prefix}-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# give ECS tasks ability to assume roles
resource "aws_iam_role" "ecs_task_role" {
  name = "${local.prefix}-ecsTaskRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# give ECS containers ability to send logs to cloudwatch
resource "aws_iam_policy" "container" {
  name        = "${local.prefix}-policy-container"
  description = "Policy that allows access to CloudWatch"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# granting permissions(policy) to the role
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# granting permissions(policy) to the role
resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.container.arn
}

# create cloudwatch group to send the logs to
resource "aws_cloudwatch_log_group" "main" {
  name = "/ecs/${local.prefix}"

  retention_in_days = 7

  tags = {
    Name        = local.prefix
    Environment = var.environment
  }
}

# describe container parameters for container
resource "aws_ecs_task_definition" "main" {
  family                   = local.prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name        = local.prefix
    image       = "${var.container_image}"
    essential   = true
    environment = var.container_environment
    portMappings = [{
      protocol      = "tcp"
      containerPort = var.container_port
      hostPort      = var.container_port
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main.name
        awslogs-stream-prefix = "ecs"
        awslogs-region        = var.region
      }
    }
  }])

  tags = {
    Name        = local.prefix
    Environment = var.environment
  }
}

# define container lifecycle
resource "aws_ecs_service" "main" {
  name                               = local.prefix
  cluster                            = var.aws_ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = var.service_desired_count
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  platform_version                   = "1.4.0"

  service_registries {
    registry_arn = aws_service_discovery_service.sds.arn
    container_name = "frontend"
  }

  network_configuration {
    security_groups  = var.ecs_service_security_groups
    subnets          = var.subnets.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = local.prefix
    container_port   = var.container_port
  }

  # we ignore task_definition changes as the revision changes on deploy
  # of a new version of the application
  # desired_count is ignored as it can change due to autoscaling policy
  // lifecycle {
  //   ignore_changes = [task_definition, desired_count]
  // }
}

# autoscaling targets
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${var.aws_ecs_cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# rules defining when to scale, if avg(ECSServiceAverageMemoryUtilization) on all containers exceeds 80, then new container created
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "${local.prefix}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# rules defining when to scale, if avg(ECSServiceAverageCPUUtilization) on all containers exceeds 60, then new container created
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${local.prefix}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 60
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# creates reference for frontend to internal dns name
resource "aws_service_discovery_service" "sds" {
  name = "frontend"

  dns_config {
        namespace_id = var.namespace_id

        dns_records {
            ttl  = 10
            type = "A"
        }

        routing_policy = "MULTIVALUE"
    }

    health_check_custom_config {
        failure_threshold = 1
    }
}
