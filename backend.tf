terraform {
  backend "s3" {
    bucket       = "terraform-state-436204347828-us-east-1"
    key          = "aws-iac/ecs-webapp/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
