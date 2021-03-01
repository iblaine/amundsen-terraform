provider "aws" {
  region     = var.region
}

terraform {
  backend "s3" {
    bucket  = "awsbe-amundsen"
    key     = "amundsen-elasticsearch.tfstate"
    region  = "us-east-1"
  }
}
