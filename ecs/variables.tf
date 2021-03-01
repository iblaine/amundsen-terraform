variable "name" {
  description = "the name of your stack, e.g. \"demo\""
  default = "amundsen"
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
  default     = "prod"
}

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
  default     = "us-east-1"
}

variable "aws-region" {
  type        = string
  description = "AWS region to launch servers."
  default     = "us-east-1"
}


variable "availability_zones" {
  description = "a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both private_subnets and public_subnets have to be defined as well"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "a list of CIDRs for private subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.0.0.0/20", "10.0.32.0/20", "10.0.64.0/20"]
}

variable "public_subnets" {
  description = "a list of CIDRs for public subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.0.16.0/20", "10.0.48.0/20", "10.0.80.0/20"]
}

variable "frontend_service_desired_count" {
  description = "Number of tasks running in parallel"
  default     = 1
}

variable "metadata_service_desired_count" {
  description = "Number of tasks running in parallel"
  default     = 1
}

variable "search_service_desired_count" {
  description = "Number of tasks running in parallel"
  default     = 1
}

variable "neo4j_service_desired_count" {
  description = "Number of tasks running in parallel"
  default     = 1
}

variable "frontend_container_port" {
  description = "The port where the Docker is exposed"
  default     = 5000
}

variable "metadata_container_port" {
  description = "The port where the Docker is exposed"
  default     = 5002
}

variable "search_container_port" {
  description = "The port where the Docker is exposed"
  default     = 5001
}

variable "frontend_container_cpu" {
  description = "The number of cpu units used by the task"
  default     = 256
}

variable "metadata_container_cpu" {
  description = "The number of cpu units used by the task"
  default     = 256
}

variable "search_container_cpu" {
  description = "The number of cpu units used by the task"
  default     = 256
}

variable "neo4j_container_cpu" {
  description = "The number of cpu units used by the task"
  default     = 1024
}

variable "frontend_container_memory" {
  description = "The amount (in MiB) of memory used by the task"
  default     = 512
}

variable "metadata_container_memory" {
  description = "The amount (in MiB) of memory used by the task"
  default     = 512
}

variable "search_container_memory" {
  description = "The amount (in MiB) of memory used by the task"
  default     = 512
}

variable "neo4j_container_memory" {
  description = "The amount (in MiB) of memory used by the task"
  default     = 8192
}

variable "frontend_health_check_path" {
  description = "Http path for task health check"
  default     = "/"
}

variable "metadata_health_check_path" {
  description = "Http path for task health check"
  default     = "/healthcheck"
}

variable "search_health_check_path" {
  description = "Http path for task health check"
  default     = "/healthcheck"
}

variable "frontend_container_image" {
  description = "Docker image for Amundsen Frontend service"
  default     = "amundsendev/amundsen-frontend:3.1.0"
}

variable "metadata_container_image" {
  description = "Docker image for Amundsen Metadata service"
  default     = "amundsendev/amundsen-metadata:3.0.0"
}

variable "search_container_image" {
  description = "Docker image for Amundsen Metadata service"
  default     = "amundsendev/amundsen-search:2.4.1"
}

variable "neo4j_container_image" {
  description = "Docker image for Amundsen Metadata service"
  default     = "neo4j:3.3.0"
}
