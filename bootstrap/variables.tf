variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state"
  type        = string
  default     = "utc-app-terraform-state-ne"
}

variable "region" {
  type    = string
  default = "us-east-1"
}