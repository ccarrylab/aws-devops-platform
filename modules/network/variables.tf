variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.100.0.0/16"
}

variable "az_count" {  # ← ADD THIS
  description = "Number of Availability Zones"
  type        = number
  default     = 2
}
