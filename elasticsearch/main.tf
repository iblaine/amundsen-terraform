locals {
  prefix = "${var.name}-${var.environment}-es"
}

# query subnets from vpc, define where to deploy ES
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = "awsbe-amundsen"
    key     = "amundsen-vpc.tfstate"
    region  = "us-east-1"
  }
}

# provides region to be used below
data "aws_region" "current" {}

# provides an account_id to be used below
data "aws_caller_identity" "current" {}

# required for ES deployment
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

# config for ES cluster, single instance
resource "aws_elasticsearch_domain" "es" {
  domain_name           = local.prefix
  elasticsearch_version = "6.7"

  cluster_config {
    instance_type = "t3.small.elasticsearch"
  }

  vpc_options {
    subnet_ids = [element(data.terraform_remote_state.vpc.outputs.private_subnets.*.id, 0)]
    security_group_ids = [data.terraform_remote_state.vpc.outputs.sg_amundsen]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.prefix}/*"
        }
    ]
}
CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 40
  }

  depends_on = [aws_iam_service_linked_role.es]
}
