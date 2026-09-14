variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "bastion_security_group_id" {
  type = string
}

variable "target_group_arns" {
  type    = list(string)
  default = []
}

variable "key_name" {
  type = string
}

variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type    = number
  default = 80
}

variable "root_volume_size" {
  type    = number
  default = 30
}

variable "app_user_data" {
  type    = string
  default = null
}

variable "enable_bastion" {
  type    = bool
  default = true
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "cpu_high_threshold" {
  type    = number
  default = 80
}

variable "cpu_low_threshold" {
  type    = number
  default = 20
}

variable "scale_out_cooldown" {
  type    = number
  default = 300
}

variable "scale_in_cooldown" {
  type    = number
  default = 300
}

variable "notification_email" {
  type    = string
  default = ""
}

variable "s3_bucket_arn" {
  type    = string
  default = ""
}

variable "efs_file_system_id" {
  type    = string
  default = ""
}

variable "efs_access_point_id" {
  type    = string
  default = ""
}

variable "db_secret_arn" {
  type    = string
  default = ""
}

variable "mount_path" {
  type    = string
  default = "/mnt/efs"
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "enable_s3_access" {
  type    = bool
  default = false
}

variable "enable_efs_access" {
  type    = bool
  default = false
}

variable "enable_secrets_access" {
  type    = bool
  default = false
}
variable "s3_bucket_name" {
  description = "S3 bucket name to pull frontend assets from. Leave empty to fall back to the placeholder page."
  type        = string
  default     = ""
}
