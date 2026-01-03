variable "vpc_name" {
  type        = string
  description = "Name prefix for the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of AZs to use"
  default     = 2
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "Extra tags to apply"
  default     = {}
}
