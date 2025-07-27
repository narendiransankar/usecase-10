variable "environment" {
  description = "Deployment environment (used for naming resources)"
  type        = string
}

variable "alb_callback_url" {
  description = "Callback URL for Cognito (ALB DNS name with /oauth2/idpresponse path)"
  type        = string
}
