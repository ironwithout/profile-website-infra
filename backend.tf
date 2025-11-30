terraform {
  backend "s3" {
    bucket       = "terraform-state-436204347828-us-east-1"
    region       = "us-east-1"
    use_lockfile = true
    # key is provided via -backend-config flag during init
    # See environments/{env}/backend.hcl for environment-specific keys
  }
}
