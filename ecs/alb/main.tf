locals {
  prefix = "${var.name}-${var.environment}-alb"
}

# define alb
resource "aws_lb" "main" {
  name               = local.prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_security_groups
  subnets            = var.subnets.*.id

  enable_deletion_protection = false

  tags = {
    Name        = local.prefix
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "frontend" {
  name        = "${local.prefix}-tg-frontend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.frontend_health_check_path
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "${local.prefix}-tg-frontend"
    Environment = var.environment
  }

  depends_on = [ aws_lb.main ]
}

# Redirect to http listener
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.frontend.id
    type             = "forward"
  }
}
