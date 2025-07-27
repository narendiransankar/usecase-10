variable "public_subnet_ids" {
description = "The public subnet id"
type = list(string)
}
variable "environment" {
  description = "The Environment we are using"
  type = string
}
variable "vpc_id" {
    description = "The VPC ID"
    type = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for ALB HTTPS listener"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN for authentication"
  type        = string
}

variable "cognito_user_pool_client_id" {
  description = "Cognito User Pool App Client ID for authentication"
  type        = string
}

variable "cognito_user_pool_domain" {
  description = "Cognito User Pool domain prefix for authentication"
  type        = string
}
