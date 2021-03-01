variable "name" {
  description = "the name of your stack, e.g. \"demo\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
}

variable "region" {
  description = "the AWS region in which resources are created"
}

variable "subnets" {
  description = "List of subnet IDs"
}

variable "ecs_service_security_groups" {
  description = "Comma separated list of security groups"
}

variable "container_cpu" {
  description = "The number of cpu units used by the task"
}

variable "container_memory" {
  description = "The amount (in MiB) of memory used by the task"
}

variable "container_image" {
  description = "Docker image to be launched"
}

variable "service_desired_count" {
  description = "Number of services running in parallel"
}

variable "container_environment" {
  description = "The container environmnent variables"
  type        = list
}

variable "aws_ecs_cluster_id" {
  description = "Fargate cluster ID"
  type        = string
}

variable "aws_ecs_cluster_name" {
  description = "Fargate cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "namespace_id" {
  description = "Service Discovery Namespace ID"
  type        = string
}

variable "efs_id" {
  description = "AWS EFS Filesystem ID"
  type        = string
}
