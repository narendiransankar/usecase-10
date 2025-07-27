output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_client_id" {
  description = "ID of the Cognito User Pool App Client"
  value       = aws_cognito_user_pool_client.main.id
}

output "user_pool_domain" {
  description = "Cognito User Pool domain prefix"
  value       = aws_cognito_user_pool_domain.main.domain
}
