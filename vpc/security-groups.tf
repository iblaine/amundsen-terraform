# open alb to port 80, 443
resource "aws_security_group" "alb" {
  name   = "${local.prefix_sg}-alb"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${local.prefix_sg}-alb"
    Environment = var.environment
  }
}

# allow frontend to see port 5000, other instances in group access to all ports/portocols
resource "aws_security_group" "amundsen" {
  name   = "${local.prefix_sg}-amundsen"
  vpc_id = aws_vpc.main.id

  ingress {
      from_port = 0
      to_port = 0
      protocol = -1
      self = true
  }

  ingress {
      from_port = 5000
      to_port = 5000
      protocol = "tcp"
      security_groups = [aws_security_group.alb.id]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${local.prefix_sg}-amundsen"
    Environment = var.environment
  }
}
