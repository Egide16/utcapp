# UTC App - AWS 3-Tier Infrastructure (Terraform)

Production-style, modular Terraform codebase provisioning a complete 3-tier web application on AWS: multi-AZ VPC, HTTPS load balancing, auto-scaling EC2 app tier, Multi-AZ RDS, shared EFS storage, S3, and Route 53 DNS - with remote state, IAM-role-based access (no static credentials), and a repeatable, environment-based deployment structure.

Skills demonstrated: Terraform (modular design, remote state, S3 native locking), AWS networking (VPC, subnets, NAT, routing, security groups), AWS compute (EC2, Auto Scaling, Launch Templates, IAM roles/SSM), AWS data services (RDS Multi-AZ, EFS, S3), AWS DNS/TLS (Route 53, ACM), CloudWatch alarms and SNS notifications, infrastructure-as-code best practices.

## Architecture

Internet -> Route 53 -> ALB (HTTPS) -> Target Group -> EC2 App Tier (Auto Scaling Group)
Then down to: RDS MySQL (Multi-AZ), EFS, S3

Key components:
- VPC: 3 Availability Zones, public, private, and database subnet tiers
- ALB: HTTP to HTTPS redirect, ACM certificate, health-checked target group
- Compute: Amazon Linux 2023 Launch Template, Auto Scaling Group with CPU-based scaling, SSM access with no static SSH keys on app instances, bastion host for break-glass SSH
- Database: RDS MySQL, Multi-AZ, password managed via AWS Secrets Manager with no static credentials
- Storage: S3 for backups, logs, and uploads (versioned, encrypted), EFS for shared app files, mounted automatically via user data
- DNS: Route 53 alias record pointing at the ALB
- State: Remote S3 backend with native S3 locking, Terraform 1.10+, no DynamoDB needed

## Repo structure

bootstrap - one-time setup, creates the S3 state bucket, run once ever
modules/network - VPC, subnets, NAT, routing, all security groups
modules/alb - load balancer, listeners, target group
modules/compute - IAM role, Launch Template, ASG, scaling, SNS, bastion
modules/database - RDS MySQL
modules/storage - S3 and EFS
modules/dns - Route 53 record
envs/dev/utc-app - dev environment, calls all modules together
envs/prod - prod environment, not yet built

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI configured with credentials that can create the resources above
- An existing EC2 key pair for bastion SSH
- An ACM certificate already issued for your domain, in the same region as the ALB
- A Route 53 hosted zone already set up for your domain

## First-time setup, once per AWS account

cd bootstrap
terraform init
terraform apply

This creates the S3 bucket that holds Terraform state for every environment. You only run this once, ever, per AWS account, not per environment.

## Deploying an environment, for example dev

1. Copy the example variables file and fill in your real values:

cd envs/dev/utc-app
cp terraform.tfvars.example terraform.tfvars

Edit terraform.tfvars with your actual bastion IP, ACM cert ARN, key pair name, notification email, and domain. This file is gitignored, never commit it.

2. Initialize and deploy:

terraform init
terraform plan
terraform apply

## Notes for contributors

- Never commit terraform.tfvars, any tfstate file, or pem keys. The gitignore already blocks these, do not override it.
- State is shared via the S3 backend with native locking. Two people running apply at the same time will be safely queued, not conflicting.
- Changes should go through a pull request rather than pushing directly to main.
- Run terraform fmt and terraform validate before opening a PR.
