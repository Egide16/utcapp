# ---------------------------------------------------------------------------
# Network — VPC, subnets, NAT, routing, all security groups
# ---------------------------------------------------------------------------

module "network" {
  source = "../../../modules/network"

  project_name = "utc-app"
  environment  = "dev"

  vpc_cidr = "10.10.0.0/16"
  az_count = 3

  bastion_ssh_cidrs = var.bastion_ssh_cidrs

  app_port = 80
}

# ---------------------------------------------------------------------------
# Storage — S3 bucket + EFS
# ---------------------------------------------------------------------------

module "storage" {
  source = "../../../modules/storage"

  project_name = "utc-app"
  environment  = "dev"

  private_subnet_ids    = module.network.private_subnet_ids
  efs_security_group_id = module.network.efs_security_group_id
}

# ---------------------------------------------------------------------------
# Frontend assets — uploaded to the existing S3 bucket, served by app instances
# ---------------------------------------------------------------------------
resource "aws_s3_object" "frontend_index" {
  bucket       = module.storage.bucket_name
  key          = "frontend/index.html"
  source       = "${path.module}/../../../../app/index.html"
  etag         = filemd5("${path.module}/../../../../app/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "frontend_style" {
  bucket       = module.storage.bucket_name
  key          = "frontend/style.css"
  source       = "${path.module}/../../../../app/style.css"
  etag         = filemd5("${path.module}/../../../../app/style.css")
  content_type = "text/css"
}

# ---------------------------------------------------------------------------
# Database — RDS MySQL, Multi-AZ
# ---------------------------------------------------------------------------

module "database" {
  source = "../../../modules/database"

  project_name = "utc-app"
  environment  = "dev"

  db_subnet_group_name       = module.network.database_subnet_group_name
  database_security_group_id = module.network.database_security_group_id
}

# ---------------------------------------------------------------------------
# ALB — HTTPS listener, target group
# ---------------------------------------------------------------------------

module "alb" {
  source = "../../../modules/alb"

  project_name = "utc-app"
  environment  = "dev"

  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id

  certificate_arn = var.certificate_arn
  target_port     = 80
}

# ---------------------------------------------------------------------------
# Compute — Launch Template, Auto Scaling Group, bastion host
# ---------------------------------------------------------------------------

module "compute" {
  source = "../../../modules/compute"

  project_name = "utc-app"
  environment  = "dev"

  vpc_id                    = module.network.vpc_id
  public_subnet_ids         = module.network.public_subnet_ids
  private_subnet_ids        = module.network.private_subnet_ids
  app_security_group_id     = module.network.app_security_group_id
  bastion_security_group_id = module.network.bastion_security_group_id

  target_group_arns = module.alb.target_group_arns

  key_name = var.key_name
  app_port = 80

  notification_email = var.notification_email

  s3_bucket_arn       = module.storage.bucket_arn
  efs_file_system_id  = module.storage.efs_file_system_id
  efs_access_point_id = module.storage.efs_access_point_id
  db_secret_arn       = module.database.master_user_secret_arn

  enable_s3_access      = true
  enable_efs_access     = true
  enable_secrets_access = true
}

# ---------------------------------------------------------------------------
# DNS
# ---------------------------------------------------------------------------

module "dns" {
  source = "../../../modules/dns"

  zone_name    = var.zone_name
  record_name  = var.record_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}