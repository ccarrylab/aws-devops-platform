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
  default     = "us-east-1"
}

variable "app_name" {
  type        = string
  default     = "observability-demo"
}

module "observability" {
  source   = "../../../modules/observability"
  app_name = var.app_name
}

output "log_group_name" {
  value       = module.observability.log_group_name
  description = "CloudWatch log group created for the app"
}

output "alerts_topic_arn" {
  value       = module.observability.alerts_topic_arn
  description = "SNS topic for alerts"
}
