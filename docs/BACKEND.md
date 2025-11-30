# Terraform Backend Setup

This project uses S3 for Terraform state storage with state locking enabled.

## Prerequisites

- AWS CLI configured with admin credentials
- AWS account ID

## 1. Create S3 Bucket

Replace `ACCOUNT_ID` with your AWS account ID:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-east-1"
export BUCKET_NAME="terraform-state-${AWS_ACCOUNT_ID}-${AWS_REGION}"

# Create bucket
aws s3api create-bucket \
  --bucket ${BUCKET_NAME} \
  --region ${AWS_REGION}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access (explicit, though enabled by default on new buckets)
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

## 2. Create IAM Policy for Backend Access

Create the policy for S3 backend access:

```bash
cat > /tmp/backend-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateS3ListBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketVersioning"
      ],
      "Resource": "arn:aws:s3:::terraform-state-ACCOUNT_ID-us-east-1"
    },
    {
      "Sid": "TerraformStateS3ReadWrite",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "arn:aws:s3:::terraform-state-ACCOUNT_ID-us-east-1/*"
    }
  ]
}
EOF

# Replace ACCOUNT_ID in the policy file
sed -i "s/ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" /tmp/backend-policy.json

# Create the policy
aws iam create-policy \
  --policy-name TerraformS3BackendPolicy \
  --policy-document file:///tmp/backend-policy.json \
  --description "Allow Terraform to manage state in S3"
```

## 3. Attach Policy to User

Attach the backend policy to your `terraform-deployer` user:

```bash
aws iam attach-user-policy \
  --user-name terraform-deployer \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/TerraformS3BackendPolicy
```

## 4. Update Backend Configuration

Update `backend.tf` with your bucket name:

```hcl
terraform {
  backend "s3" {
    bucket       = "terraform-state-ACCOUNT_ID-us-east-1"
    region       = "us-east-1"
    use_lockfile = true
    # key is provided via -backend-config flag during init
  }
}
```

## Environment-Specific State Keys

Each environment has its own state file via `backend.hcl`:

**environments/dev/backend.hcl**:
```hcl
key = "aws-iac/ecs-webapp/dev/terraform.tfstate"
```

**environments/prod/backend.hcl**:
```hcl
key = "aws-iac/ecs-webapp/prod/terraform.tfstate"
```

## Initialization

Initialize Terraform with environment-specific backend:

```bash
# For dev
terraform init -backend-config=environments/dev/backend.hcl

# For prod
terraform init -backend-config=environments/prod/backend.hcl
```

## Security Notes

- ✅ Versioning enabled for state recovery
- ✅ Encryption at rest with AES256
- ✅ Public access blocked
- ✅ Separate state files per environment
- 🔒 Consider enabling S3 bucket logging for audit trail
- 🔒 Consider adding lifecycle rules to manage old versions
