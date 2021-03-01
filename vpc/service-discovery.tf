# private hosted zone in route53, enables ecs to use private dns names instead of rely on IPs, typically used to manage ephemeral containers
resource "aws_service_discovery_private_dns_namespace" "amundsen" {
  name        = "${var.environment}.amundsen.local"
  description = "amundsen"
  vpc         = aws_vpc.main.id
}
