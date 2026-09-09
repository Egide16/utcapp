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

variable "alb_security_group_id" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "target_port" {
  type    = number
  default = 80
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_healthy_threshold" {
  type    = number
  default = 3
}

variable "health_check_unhealthy_threshold" {
  type    = number
  default = 3
}

variable "health_check_interval" {
  type    = number
  default = 30
}

variable "health_check_timeout" {
  type    = number
  default = 5
}

variable "deregistration_delay" {
  type    = number
  default = 30
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "access_logs_bucket" {
  type    = string
  default = ""
}

variable "access_logs_prefix" {
  type    = string
  default = "alb"
}

variable "tags" {
  type    = map(string)
  default = {}
}