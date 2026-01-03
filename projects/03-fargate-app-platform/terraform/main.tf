terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "app_name" {
  type        = string
  description = "App name"
  default     = "fargate-demo"
}

module "network" {
  source   = "../../../modules/network"
  vpc_name = "${var.app_name}-vpc"
}

module "observability" {
  source   = "../../../modules/observability"
  app_name = var.app_name
}

module "ecs_app" {
  source         = "../../../modules/ecs_fargate_app"
  app_name       = var.app_name
  vpc_id         = module.network.vpc_id
  subnets        = module.network.private_subnets
  public_subnets = module.network.public_subnets
  log_group_name = module.observability.log_group_name
}

output "app_url" {
  value       = "http://${module.ecs_app.alb_dns_name}"
  description = "Application URL"
}
