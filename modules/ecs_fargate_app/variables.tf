variable "app_name" {
  type        = string
  description = "Application name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets for Fargate tasks"
}

variable "public_subnets" {
  type        = list(string)
  description = "Subnets for ALB"
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group name"
}
