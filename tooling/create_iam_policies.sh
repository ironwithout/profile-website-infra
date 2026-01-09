#!/usr/bin/env bash

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODULES_DIR="${PROJECT_ROOT}/modules"
POLICY_NAME_PREFIX="terraform-profile-website-"

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "[ERROR] AWS CLI is not installed. Please install it first."
        exit 1
    fi
}

# Function to check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "[ERROR] AWS credentials are not configured or invalid."
        exit 1
    fi
}

# Function to create or update IAM policy
create_or_update_policy() {
    local module_name=$1
    local policy_file=$2
    local policy_name=$3
    local description="IAM policy to manage ${module_name} related resources from terraform to deploy the profile website infrastructure"

    echo "Processing module: ${module_name}"

    # Check if policy file exists
    if [[ ! -f "${policy_file}" ]]; then
        echo "[ERROR] Policy file not found: ${policy_file}"
        return 1
    fi

    # Validate JSON syntax
    if ! jq empty "${policy_file}" 2>/dev/null; then
        echo "[ERROR] Invalid JSON in policy file: ${policy_file}"
        return 1
    fi

    # Check if policy already exists
    local policy_arn=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${policy_name}'].Arn" --output text 2>/dev/null || true)

    if [[ -n "${policy_arn}" ]]; then
        echo "[WARN] Policy '${policy_name}' already exists (ARN: ${policy_arn})"
        echo "Creating new policy version..."
        local new_version=$(aws iam create-policy-version \
            --policy-arn "${policy_arn}" \
            --policy-document "file://${policy_file}" \
            --set-as-default \
            --query 'PolicyVersion.VersionId' \
            --output text)

        echo "✓ Updated policy '${policy_name}' with new version: ${new_version}"
    else
        echo "Creating new policy '${policy_name}'..."
        policy_arn=$(aws iam create-policy \
            --policy-name "${policy_name}" \
            --policy-document "file://${policy_file}" \
            --description "${description}" \
            --query 'Policy.Arn' \
            --output text)

        echo "✓ Created policy '${policy_name}' (ARN: ${policy_arn})"
    fi

    return 0
}

# Function to attach policy to a user
attach_policy() {
    local policy_arn=$1
    local attach_to=$2

    aws iam attach-user-policy --user-name "${attach_to}" --policy-arn "${policy_arn}"
    echo "✓ Attached policy to user: ${attach_to}"
    echo ""
    return 0
}

# Main execution
main() {
    local user=$1

    echo "=== IAM Policy Creation Script ==="
    echo ""

    # Preflight checks
    check_aws_cli
    check_aws_credentials
    echo ""

    # Find all iam-policy.json files in modules
    local policy_files=()
    while IFS= read -r -d '' file; do
        policy_files+=("$file")
    done < <(find "${MODULES_DIR}" -type f -name "iam-policy.json" -print0 | sort -z)

    if [[ ${#policy_files[@]} -eq 0 ]]; then
        echo "[ERROR] No iam-policy.json files found in ${MODULES_DIR}"
        exit 1
    fi

    echo "Found ${#policy_files[@]} policy file(s):"
    for file in "${policy_files[@]}"; do
        echo "  - ${file}"
    done
    echo ""

    # Process each policy file
    local success_count=0
    local fail_count=0

    for policy_file in "${policy_files[@]}"; do
        # Extract module name from path (e.g., modules/network/iam-policy.json -> network)
        local module_name=$(basename "$(dirname "${policy_file}")")
        local policy_name="${POLICY_NAME_PREFIX}${module_name}"

        if create_or_update_policy "${module_name}" "${policy_file}" "${policy_name}"; then
            local policy_arn=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${policy_name}'].Arn" --output text 2>/dev/null || true)
            if ! attach_policy "${policy_arn}" "${user}"; then
                echo "[ERROR] Failed attaching policy: ${policy_name}"
            fi
        else
            echo "[ERROR] Failed creating policy: ${policy_name}"
            exit 1
        fi
    done

    echo "✓ All policies created/updated successfully!"
    echo ""
}

# Run main function
main "$@"
