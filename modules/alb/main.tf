
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
  }
}

# Target Group for Patient Service
resource "aws_lb_target_group" "patient_service" {
  name     = "${var.environment}-patient-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-patient-tg"
    Environment = var.environment
  }
}

# Target Group for Appointment Service
resource "aws_lb_target_group" "appointment_service" {
  name     = "${var.environment}-apmt-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-appointment-tg"
    Service     = "appointment-service"
    Environment = var.environment
  }
}

# New HTTPS listener on port 443
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port     = 443
  protocol = "HTTPS"
  certificate_arn = var.certificate_arn        # ACM certificate ARN for the ALB (passed in)
  ssl_policy     = "ELBSecurityPolicy-2016-08" # Use a predefined SSL policy (optional)

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }

  tags = {
    Name        = "${var.environment}-alb-listener-https"
    Environment = var.environment
  }
}


# Listener Rule for Patient Service (requires Cognito auth)
resource "aws_lb_listener_rule" "patient_service" {
  listener_arn = aws_lb_listener.main.arn     # attach to HTTPS listener
  priority     = 100

  action {
    type = "authenticate-cognito"
    order = 1
    authenticate_cognito {
      user_pool_arn       = var.cognito_user_pool_arn
      user_pool_client_id = var.cognito_user_pool_client_id
      user_pool_domain    = var.cognito_user_pool_domain
      scope               = "openid"                  # request OpenID scope (ID token)
      session_cookie_name = "ALBAuthSession_Patient"  # unique cookie name for this rule
      on_unauthenticated_request = "authenticate"     # redirect unauthenticated users to login
    }
  }

  action {
    type             = "forward"
    order            = 2
    target_group_arn = aws_lb_target_group.patient_service.arn
  }

  condition {
    path_pattern {
      values = ["/patients/*"]
    }
  }

  tags = {
    Name        = "${var.environment}-patient-rule"
    Service     = "patient-service"
    Environment = var.environment
  }
}

# Listener Rule for Appointment Service (requires Cognito auth)
resource "aws_lb_listener_rule" "appointment_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 200

  action {
    type = "authenticate-cognito"
    order = 1
    authenticate_cognito {
      user_pool_arn       = var.cognito_user_pool_arn
      user_pool_client_id = var.cognito_user_pool_client_id
      user_pool_domain    = var.cognito_user_pool_domain
      scope               = "openid"
      session_cookie_name = "ALBAuthSession_Appointment"
      on_unauthenticated_request = "authenticate"
    }
  }

  action {
    type             = "forward"
    order            = 2
    target_group_arn = aws_lb_target_group.appointment_service.arn
  }

  condition {
    path_pattern {
      values = ["/appointments/*"]
    }
  }

  tags = {
    Name        = "${var.environment}-appointment-rule"
    Service     = "appointment-service"
    Environment = var.environment
  }
}

# (Unchanged) Health check rule – keep without auth so health endpoint is publicly accessible
resource "aws_lb_listener_rule" "health_check" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 50

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"status\":\"healthy\",\"services\":[\"patient\",\"appointment\"]}"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }

  tags = {
    Name        = "${var.environment}-health-rule"
    Environment = var.environment
  }
}

