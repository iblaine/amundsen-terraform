output "id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public
}

output "private_subnets" {
  value = aws_subnet.private
}

output "cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "sg_alb" {
  value = aws_security_group.alb.id
}

output "sg_amundsen" {
  value = aws_security_group.amundsen.id
}

output "amundsen_private_dns_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.amundsen.id
}

output "efs_id" {
  value = aws_efs_file_system.amundsen.id
}
