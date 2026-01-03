variable "github_repo" {
  type        = string
  description = "GitHub repo in the form owner/name"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the GitHub OIDC provider in IAM"
}
