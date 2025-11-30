# IAM Policies for Terraform Deployment

This directory contains IAM policy definitions for the `terraform-deployer` user.

## Policy Evolution

As we build more modules, we incrementally add permissions following **least-privilege principle**.

### Current Policies

#### `terraform-deployer-network.json`
**Scope**: Network module only  
**Permissions**: VPC, Subnets, Internet Gateway, Route Tables, Security Groups  
**Applied**: ✅ Active

```bash
# Create initial policy
aws iam create-policy \
  --policy-name TerraformNetworkPolicy \
  --policy-document file://terraform-deployer-network.json

# Update existing policy (creates new version)
aws iam create-policy-version \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/TerraformNetworkPolicy \
  --policy-document file://terraform-deployer-network.json \
  --set-as-default

# Attach policies to the terraform-deployer user
aws iam attach-user-policy \
  --user-name terraform-deployer \
  --policy-arn arn:aws:iam::accountid:policy/TerraformNetworkPolicy
```

## Future Policies

As we add modules (ECS, ALB, ECR, etc.), we'll:
1. Update the JSON file with new permissions
2. Commit to git for review
3. Create new policy version in AWS
4. Test deployment

## Usage

```bash
# Switch to admin profile
export AWS_PROFILE=admin

# Update policy (replace ACCOUNT_ID with your AWS account)
aws iam create-policy-version \
  --policy-arn arn:aws:iam::accountid:policy/TerraformNetworkPolicy \
  --policy-document file://iam-policies/terraform-deployer-network.json \
  --set-as-default

# AWS keeps up to 5 versions. Delete old ones if needed:
aws iam list-policy-versions --policy-arn arn:aws:iam::accountid:policy/TerraformNetworkPolicy
aws iam delete-policy-version --policy-arn arn:aws:iam::accountid:policy/TerraformNetworkPolicy --version-id v1
```

## Security Notes

- ⚠️ These policies use `"Resource": "*"` for simplicity in dev/learning
- 🔒 For production, scope down to specific resource ARNs where possible
- 📝 Always review policy changes in PRs before applying
- 🔄 Rotate access keys regularly (every 90 days)
