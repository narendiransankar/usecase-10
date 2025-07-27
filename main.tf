
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  pub_sub_count  = var.pub_sub_count
  priv_sub_count = var.priv_sub_count
  #nat_count      = var.nat_count
}

module "cognito" {
  source           = "./modules/cognito"
  environment      = var.environment
  # Pass the ALB callback URL (using ALB DNS from output if available, or construct after ALB creation)
  alb_callback_url = "https://${module.alb.alb_dns_name}/oauth2/idpresponse"
}



# ALB Module – create ALB with HTTPS & Cognito auth
module "alb" {
  source                   = "./modules/alb"
  public_subnet_ids        = module.vpc.public_subnet_ids
  vpc_id                   = module.vpc.vpc_id        # VPC ID from VPC module
  environment              = var.environment

  certificate_arn          = var.certificate_arn      # ACM cert for HTTPS
  cognito_user_pool_arn    = module.cognito.user_pool_arn
  cognito_user_pool_client_id = module.cognito.user_pool_client_id
  cognito_user_pool_domain    = module.cognito.user_pool_domain
}

module "ecs" {
  source = "./modules/ecs"
  private_subnet_ids = module.vpc.private_subnet_ids
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  patient_repo_uri = var.patient_repo_uri
  appointment_repo_uri = var.appointment_repo_uri
  alb_sg_id = module.alb.alb_sg_id
  patient_target_group_arn = module.alb.patient_tg_arn
  appointment_target_group_arn = module.alb.appointment_tg_arn
}

module "sns" {
  source       = "./modules/mod-sns"
  environment  = var.environment
  alert_email  = var.alert_email
}

module "cloudwatch" {
  source           = "./modules/mod-cloudwatch"
  environment      = var.environment
  ecs_cluster_name = var.ecs_cluster_name
  sns_topic_arn    = module.sns.topic_arn
}

module "cloudtrail" {
  source      = "./modules/mod-cloudtrail"
  environment = var.environment
}
