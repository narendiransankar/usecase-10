resource "aws_cognito_user_pool" "main" {
  name                = "${var.environment}-user-pool"
  auto_verified_attributes = ["email"]     # Auto-verify emails (optional)
  alias_attributes        = ["email"]      # Users can sign in with email
  mfa_configuration       = "OFF"          # No MFA for simplicity (optional)
}

resource "aws_cognito_user_pool_client" "main" {
  name            = "${var.environment}-app-client"
  user_pool_id    = aws_cognito_user_pool.main.id
  generate_secret = true

  # Enable OAuth 2.0 code grant flow for ALB authentication
  allowed_oauth_flows_user_pool_client = true 
  allowed_oauth_flows       = ["code"]                      # Use authorization code grant (requires client secret)
  allowed_oauth_scopes      = ["openid", "email", "profile"]# Scopes to request
  supported_identity_providers = ["COGNITO"]                # Using Cognito user pool as IdP

  callback_urls = [ var.alb_callback_url ]   # ALB redirect URI after login (must be lowercase):contentReference[oaicite:1]{index=1}
  logout_urls   = [ var.alb_callback_url ]   # (Optional) Redirect here on logout

  # Prevent user existence errors (optional best practice for new pools)
  prevent_user_existence_errors = true
}

resource "aws_cognito_user_pool_domain" "main" {
  user_pool_id = aws_cognito_user_pool.main.id
  domain       = "${var.environment}-auth-domain"  # Cognito hosted domain prefix (must be globally unique)
}
