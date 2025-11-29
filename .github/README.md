# GitHub Actions CI/CD Setup

## Overview

This repository uses GitHub Actions for automated Terraform validation, linting, and planning on every pull request to `main`.

## Workflows

### `terraform-validate.yml`
**Triggers**: Pull requests and pushes to `main`

**Steps**:
1. ✅ **Format Check** - Ensures code follows Terraform style
2. ⚙️ **Init** - Initializes Terraform (without backend)
3. 🤖 **Validate** - Checks configuration syntax and consistency
4. 🔍 **TFLint** - Runs AWS-specific linting rules
5. 💬 **PR Comment** - Posts results with plan output as PR comment
6. 📊 **Summary** - Creates job summary

## Local Testing

Run the same checks locally before pushing:

```bash
# Format check
terraform fmt -check -recursive

# Initialize
terraform init

# Validate
terraform validate

# TFLint (install first: https://github.com/terraform-linters/tflint)
tflint --init
tflint --recursive

# Plan
terraform plan -var-file=environments/dev/terraform.tfvars
```

## TFLint Configuration

The `.tflint.hcl` file configures:
- AWS-specific rules (resource naming, deprecated features)
- Variable and output documentation requirements
- Unused declaration detection
- Type checking

## Workflow Permissions

The workflow requires:
- `contents: read` - Read repository code
- `pull-requests: write` - Comment on PRs

## Future Enhancements

- [ ] Add Checkov security scanning
- [ ] Add cost estimation with Infracost
- [ ] Switch to OIDC authentication (remove access keys)
- [ ] Add deployment workflow for auto-apply on merge to main
- [ ] Environment-specific workflows (dev/prod)
- [ ] Terraform docs generation

## Troubleshooting

### "Format check failed"
Run `terraform fmt -recursive` locally and commit changes.
