provider "aws" {
  region     = var.aws-region
}

# query subnets from vpc, define where to deploy services
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = "awsbe-amundsen"
    key     = "amundsen-vpc.tfstate"
    region  = "us-east-1"
  }
}

# used to query ES
data "terraform_remote_state" "elasticsearch" {
  backend = "s3"
  config = {
    bucket  = "awsbe-amundsen"
    key     = "amundsen-elasticsearch.tfstate"
    region  = "us-east-1"
  }
}

# deploy alb
module "alb" {
  source              = "./alb"
  name                = var.name
  vpc_id              = data.terraform_remote_state.vpc.outputs.id
  subnets             = data.terraform_remote_state.vpc.outputs.public_subnets
  environment         = var.environment
  alb_security_groups = [data.terraform_remote_state.vpc.outputs.sg_alb]
  frontend_health_check_path   = var.frontend_health_check_path
  metadata_health_check_path   = var.metadata_health_check_path
  search_health_check_path     = var.search_health_check_path
  frontend_container_port      = var.frontend_container_port
  metadata_container_port      = var.metadata_container_port
  search_container_port        = var.search_container_port
}

# deploy our fargate clusters
module "fargate" {
  source                      = "./fargate"
  name                        = var.name
  environment                 = var.environment
}

# frontend service
module "amundsen-frontend-service" {
  source                      = "./services/amundsen-frontend"
  name                        = var.name
  environment                 = var.environment
  region                      = var.aws-region
  subnets                     = data.terraform_remote_state.vpc.outputs.private_subnets
  target_group_arn            = module.alb.target_group_frontend_arn
  ecs_service_security_groups = [data.terraform_remote_state.vpc.outputs.sg_amundsen]
  container_port              = var.frontend_container_port
  container_cpu               = var.frontend_container_cpu
  container_memory            = var.frontend_container_memory
  service_desired_count       = var.frontend_service_desired_count
  namespace_id                = data.terraform_remote_state.vpc.outputs.amundsen_private_dns_namespace_id
  container_environment = [
    {
      name = "LOG_LEVEL",
      value = "DEBUG"
    },
    {
      name = "SEARCHSERVICE_BASE",
      value = "http://search.prod.amundsen.local:${var.search_container_port}"
    },
    {
      name = "METADATASERVICE_BASE",
      value = "http://metadata.prod.amundsen.local:${var.metadata_container_port}"
    },
    {
      name = "FRONTEND_SVC_CONFIG_MODULE_CLASS",
      value = "amundsen_application.config.TestConfig"
    },
    {
      name = "PORT",
      value = var.frontend_container_port
    }
  ]
  container_image = var.frontend_container_image
  aws_ecs_cluster_id = module.fargate.aws_ecs_cluster_id
  aws_ecs_cluster_name = module.fargate.aws_ecs_cluster_name
}

# metadata service
module "amundsen-metadata-service" {
  source                      = "./services/amundsen-metadata"
  name                        = var.name
  environment                 = var.environment
  vpc_id                      = data.terraform_remote_state.vpc.outputs.id
  region                      = var.aws-region
  subnets                     = data.terraform_remote_state.vpc.outputs.private_subnets
  ecs_service_security_groups = [data.terraform_remote_state.vpc.outputs.sg_amundsen]
  container_port              = var.metadata_container_port
  container_cpu               = var.metadata_container_cpu
  container_memory            = var.metadata_container_memory
  service_desired_count       = var.metadata_service_desired_count
  namespace_id = data.terraform_remote_state.vpc.outputs.amundsen_private_dns_namespace_id
  container_environment = [
    {
      name = "LOG_LEVEL",
      value = "DEBUG"
    },
    {
      name = "PORT",
      value = var.metadata_container_port
    },
    {
      name = "PROXY_HOST",
      value = "bolt://neo4j.prod.amundsen.local"
    }
  ]
  container_image = var.metadata_container_image
  aws_ecs_cluster_id = module.fargate.aws_ecs_cluster_id
  aws_ecs_cluster_name = module.fargate.aws_ecs_cluster_name
}

# search service
module "amundsen-search-service" {
  source                      = "./services/amundsen-search"
  name                        = var.name
  environment                 = var.environment
  vpc_id                      = data.terraform_remote_state.vpc.outputs.id
  region                      = var.aws-region
  subnets                     = data.terraform_remote_state.vpc.outputs.private_subnets
  ecs_service_security_groups = [data.terraform_remote_state.vpc.outputs.sg_amundsen]
  container_port              = var.search_container_port
  container_cpu               = var.search_container_cpu
  container_memory            = var.search_container_memory
  service_desired_count       = var.search_service_desired_count
  namespace_id                = data.terraform_remote_state.vpc.outputs.amundsen_private_dns_namespace_id
  container_environment = [
    {
      name = "LOG_LEVEL",
      value = "DEBUG"
    },
    {
      name = "PORT",
      value = var.search_container_port
    },
    {
      name = "CREDENTIALS_PROXY_USER",
      value = ""
    },
    {
      name = "CREDENTIALS_PROXY_PASSWORD",
      value = ""
    },
    {
      name = "PROXY_ENDPOINT",
      value = "https://${data.terraform_remote_state.elasticsearch.outputs.es_endpoint}"
    }
  ]
  container_image = var.search_container_image
  aws_ecs_cluster_id = module.fargate.aws_ecs_cluster_id
  aws_ecs_cluster_name = module.fargate.aws_ecs_cluster_name
}

# neo4j db
module "amundsen-neo4j-service" {
  source                      = "./services/amundsen-neo4j"
  name                        = var.name
  environment                 = var.environment
  vpc_id                      = data.terraform_remote_state.vpc.outputs.id
  region                      = var.aws-region
  subnets                     = data.terraform_remote_state.vpc.outputs.private_subnets
  ecs_service_security_groups = [data.terraform_remote_state.vpc.outputs.sg_amundsen]
  container_cpu               = var.neo4j_container_cpu
  container_memory            = var.neo4j_container_memory
  service_desired_count       = var.neo4j_service_desired_count
  namespace_id = data.terraform_remote_state.vpc.outputs.amundsen_private_dns_namespace_id
  efs_id = data.terraform_remote_state.vpc.outputs.efs_id
  container_environment = [
    {
      name = "LOG_LEVEL",
      value = "DEBUG"
    },
    {
      name = "NEO4J_AUTH",
      value = "neo4j/test"
    }
  ]
  container_image = var.neo4j_container_image
  aws_ecs_cluster_id = module.fargate.aws_ecs_cluster_id
  aws_ecs_cluster_name = module.fargate.aws_ecs_cluster_name
}
