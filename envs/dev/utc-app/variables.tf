variable "bastion_ssh_cidrs" {
  description = "CIDR(s) allowed to SSH into the bastion host"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the ALB HTTPS listener"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for bastion SSH access"
  type        = string
}

variable "notification_email" {
  description = "Email subscribed to Auto Scaling Group SNS notifications"
  type        = string
  default     = ""
}

variable "zone_name" {
  description = "Root Route 53 hosted zone name"
  type        = string
}

variable "record_name" {
  description = "Full domain name for this environment's DNS record"
  type        = string
}