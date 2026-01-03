terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "../../../modules/network"
  
  vpc_name = "fargate-app-platform"
  cidr     = "10.100.0.0/16"
  az_count = 2
}

module "monitoring" {
  source = "../../../modules/monitoring"
  
  app_name = "fargate-app-platform"
  vpc_id   = module.network.vpc_id
}
