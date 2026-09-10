# UTC Student Portal Infrastructure as Code

This repository contains the modular Terraform Infrastructure as Code (IaC) required to deploy the AWS multi-tier architecture for the UTC Student Services Portal.

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

## Directory Structure

utcapp/
+-- envs/
|   +-- dev/
|   |   +-- utc-app/         # Dev environment instantiation
|   +-- prod/                # Production environment (not yet built)
+-- modules/
|   +-- network/             # VPC, public/private/database subnets, IGW, NAT Gateways, security groups
|   +-- alb/                 # ALB, Target Group, HTTPS Listener
|   +-- compute/             # Launch Template, Auto Scaling Group, Scaling Policies, IAM roles, bastion host
|   +-- database/            # RDS MySQL, DB Subnet Group, Secrets Manager
|   +-- storage/             # S3 Buckets, EFS Filesystem, Mount Targets
|   +-- dns/                 # Route 53 record
+-- bootstrap/                # One-time setup: creates the S3 state bucket
+-- README.md
