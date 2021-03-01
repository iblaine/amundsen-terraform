locals {
  prefix = "${var.name}-${var.environment}-cluster"
}

# define amundsen cluster
resource "aws_ecs_cluster" "main" {
  name = local.prefix
  tags = {
    Name        = local.prefix
    Environment = var.environment
  }
}
