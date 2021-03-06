locals {
  prefix = "${var.name}-${var.environment}-task-neo4j"
}

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


resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.container.arn
}

resource "aws_cloudwatch_log_group" "main" {
  name = "/ecs/${local.prefix}"

  retention_in_days = 7

  tags = {
    Name        = local.prefix
    Environment = var.environment
  }
}

# neo4j mount points defined for container
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
    mountPoints = [
      {
        containerPath = "/neo4j/data"
        readOnly      = false
        sourceVolume  = "neo4j_data"
      },
      {
        containerPath = "/conf"
        readOnly      = false
        sourceVolume  = "neo4j_conf"
      },
      {
        containerPath = "/backup"
        readOnly      = false
        sourceVolume  = "neo4j_backup"
      }
    ]
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 7474
        hostPort      = 7474
      },
      {
        protocol      = "tcp"
        containerPort = 7687
        hostPort      = 7687
      }
    ]
    ulimits = [
      {
        name      = "nofile"
        hardLimit = 100000
        softLimit = 100000
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main.name
        awslogs-stream-prefix = "ecs"
        awslogs-region        = var.region
      }
    }
  }])

  volume {
    name = "neo4j_data"
    efs_volume_configuration {
      file_system_id = var.efs_id
      root_directory = "/neo4j/data"
    }
  }

  volume {
    name = "neo4j_conf"
    efs_volume_configuration {
      file_system_id = var.efs_id
      root_directory = "/conf"
    }
  }

  volume {
    name = "neo4j_backup"
    efs_volume_configuration {
      file_system_id = var.efs_id
      root_directory = "/backup"
    }
  }

  tags = {
    Name        = local.prefix
    Environment = var.environment
  }
}

resource "aws_ecs_service" "main" {
  name                               = local.prefix
  cluster                            = var.aws_ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = var.service_desired_count
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  platform_version                   = "1.4.0"

  service_registries {
    registry_arn = aws_service_discovery_service.sds.arn
    container_name = "search"
  }

  network_configuration {
    security_groups  = var.ecs_service_security_groups
    subnets          = var.subnets.*.id
    assign_public_ip = false
  }
}


resource "aws_service_discovery_service" "sds" {
  name = "neo4j"

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
