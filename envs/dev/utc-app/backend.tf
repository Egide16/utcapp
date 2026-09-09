terraform {
  backend "s3" {
    bucket       = "utc-app-terraform-state-ne"
    key          = "dev/utc-app/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}