terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "env_name" {
  type        = string
  description = "Name of the short-lived environment"
}

locals {
  app_name    = "env-factory"
  environment = var.env_name
  tags = {
    Environment = var.env_name
    Purpose     = "self-service-env"
    ManagedBy   = "Terraform"
  }
}

module "network" {
  source      = "../../../modules/network"
  vpc_name    = local.app_name
  environment = local.environment
  tags        = local.tags
}

module "observability" {
  source   = "../../../modules/observability"
  app_name = "${local.app_name}-${local.environment}"
}

module "ecs_app" {
  source         = "../../../modules/ecs_fargate_app"
  app_name       = "${local.app_name}-${local.environment}"
  vpc_id         = module.network.vpc_id
  subnets        = module.network.private_subnets
  public_subnets = module.network.public_subnets
  log_group_name = module.observability.log_group_name
}

output "env_app_url" {
  value       = "http://${module.ecs_app.alb_dns_name}"
  description = "URL for this short-lived environment"
}
