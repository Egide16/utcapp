variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "efs_security_group_id" {
  type    = string
  default = ""
}

variable "enable_efs" {
  type    = bool
  default = true
}

variable "efs_transition_to_ia" {
  type    = string
  default = "AFTER_30_DAYS"
}

variable "bucket_name" {
  type    = string
  default = ""
}

variable "logs_expiration_days" {
  type    = number
  default = 90
}

variable "backups_glacier_transition_days" {
  type    = number
  default = 30
}

variable "force_destroy_bucket" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}