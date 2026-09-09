variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "az_count" {
  type    = number
  default = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "az_count must be between 2 and 6."
  }
}

variable "availability_zones" {
  type    = list(string)
  default = []
}

variable "public_subnet_newbits" {
  type    = number
  default = 8
}

variable "private_subnet_newbits" {
  type    = number
  default = 8
}

variable "database_subnet_newbits" {
  type    = number
  default = 8
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = []
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = []
}

variable "database_subnet_cidrs" {
  type    = list(string)
  default = []
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "create_database_subnets" {
  type    = bool
  default = true
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "alb_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "alb_ports" {
  type    = list(number)
  default = [80, 443]
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "bastion_ssh_cidrs" {
  type    = list(string)
  default = []
}

variable "allow_all_egress" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}