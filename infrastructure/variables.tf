variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "platform"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "Cohen Carryl"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "platform-eks"
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "platform_db"
}

variable "database_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "alert_email" {
  description = "Email for alerts and notifications"
  type        = string
  default     = "cohen.carryl@gmail.com"
}

variable "monthly_budget" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "600"
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway (saves $32/month, slightly less HA)"
  type        = bool
  default     = false
}
