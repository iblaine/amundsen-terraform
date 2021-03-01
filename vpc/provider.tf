terraform {
  backend "s3" {
    bucket  = "awsbe-amundsen"
    key     = "amundsen-vpc.tfstate"
    region  = "us-east-1"
  }
}

provider "aws" {
  region     = var.region
}
