variable "name" {
  description = "the name of your stack, e.g. \"demo\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
}

variable "subnets" {
  description = "Comma separated list of subnet IDs"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "alb_security_groups" {
  description = "Comma separated list of security groups"
}

variable "alb_tls_cert_arn" {
  description = "The ARN of the certificate that the ALB uses for https"
  default = null
}

variable "frontend_health_check_path" {
  description = "Path to check if the service is healthy, e.g. \"/status\""
}

variable "metadata_health_check_path" {
  description = "Path to check if the service is healthy, e.g. \"/status\""
}

variable "search_health_check_path" {
  description = "Path to check if the service is healthy, e.g. \"/status\""
}

variable "frontend_container_port" {
  description = "The port where the Docker is exposed"
}

variable "metadata_container_port" {
  description = "The port where the Docker is exposed"
}

variable "search_container_port" {
  description = "The port where the Docker is exposed"
}
