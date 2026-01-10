# S3 Module

IAM policy for using S3 as a Terraform state backend.

## Purpose

This module contains the IAM policy required for Terraform to store and manage state files in S3. It grants the minimum permissions needed for state locking and versioning.

## Permissions

| Permission | Resource | Purpose |
|------------|----------|---------|
| `s3:ListBucket` | Bucket | List objects, check if state exists |
| `s3:GetBucketVersioning` | Bucket | Verify versioning is enabled |
| `s3:GetObject` | Objects | Read current state |
| `s3:PutObject` | Objects | Write updated state |
| `s3:DeleteObject` | Objects | Remove state lock file (`.tflock`) |
| `s3:GetObjectVersion` | Objects | Access previous state versions |

## Resource Scope

The policy is scoped to buckets matching `terraform-state-profile-website*`:

```
arn:aws:s3:::terraform-state-profile-website*      # Bucket-level
arn:aws:s3:::terraform-state-profile-website*/*    # Object-level
```

## State Locking

This project uses S3 native locking (`use_lockfile = true` in `backend.tf`) instead of DynamoDB. The `s3:DeleteObject` permission is required to release the `.tflock` file after operations complete.
