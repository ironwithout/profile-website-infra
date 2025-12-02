# Data sources and validations

# Get current AWS account information
data "aws_caller_identity" "current" {}

# Validate we're using the correct AWS account
resource "terraform_data" "account_validation" {
  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
      error_message = <<-EOT
        AWS Account mismatch!
        Expected: ${var.aws_account_id}
        Current:  ${data.aws_caller_identity.current.account_id}
        
        You may be using the wrong AWS credentials or profile.
        Check your AWS_PROFILE environment variable or AWS credentials.
      EOT
    }
  }
}
