#!/usr/bin/env bash

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODULES_DIR="${PROJECT_ROOT}/modules"
POLICY_NAME_PREFIX="terraform-profile-website-"

# Function to display usage
usage() {
    echo "Usage: $0 --type <user|role> --name <name>"
    echo ""
    echo "Options:"
    echo "  --type, -t    Type of IAM principal (user or role)"
    echo "  --name, -n    Name of the IAM user or role to attach policies to"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --type user --name terraform-deployer"
    echo "  $0 --type role --name github-actions-terraform"
    exit 1
}

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

        # Get all policy versions sorted by creation date (oldest first)
        local version_count=$(aws iam list-policy-versions \
            --policy-arn "${policy_arn}" \
            --query 'length(Versions)' \
            --output text)

        # AWS allows max 5 versions - delete oldest non-default if at limit
        if [[ "${version_count}" -ge 5 ]]; then
            echo "Policy has ${version_count} versions (max 5). Deleting oldest non-default version..."

            # Find the oldest non-default version
            local oldest_version=$(aws iam list-policy-versions \
                --policy-arn "${policy_arn}" \
                --query "Versions[?IsDefaultVersion==\`false\`] | sort_by(@, &CreateDate) | [0].VersionId" \
                --output text)

            if [[ -n "${oldest_version}" && "${oldest_version}" != "None" ]]; then
                aws iam delete-policy-version \
                    --policy-arn "${policy_arn}" \
                    --version-id "${oldest_version}"
                echo "✓ Deleted old version: ${oldest_version}"
            else
                echo "[ERROR] Cannot delete any version - all versions may be default"
                return 1
            fi
        fi

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

# Function to attach policy to a user or role
attach_policy() {
    local policy_arn=$1
    local principal_type=$2
    local principal_name=$3

    if [[ "${principal_type}" == "user" ]]; then
        aws iam attach-user-policy --user-name "${principal_name}" --policy-arn "${policy_arn}"
        echo "✓ Attached policy to user: ${principal_name}"
    elif [[ "${principal_type}" == "role" ]]; then
        aws iam attach-role-policy --role-name "${principal_name}" --policy-arn "${policy_arn}"
        echo "✓ Attached policy to role: ${principal_name}"
    else
        echo "[ERROR] Invalid principal type: ${principal_type}"
        return 1
    fi
    echo ""
    return 0
}

# Main execution
main() {
    local principal_type=""
    local principal_name=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type|-t)
                principal_type="$2"
                shift 2
                ;;
            --name|-n)
                principal_name="$2"
                shift 2
                ;;
            --help|-h)
                usage
                ;;
            *)
                echo "[ERROR] Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "${principal_type}" || -z "${principal_name}" ]]; then
        echo "[ERROR] Both --type and --name are required"
        echo ""
        usage
    fi

    # Validate principal type
    if [[ "${principal_type}" != "user" && "${principal_type}" != "role" ]]; then
        echo "[ERROR] Type must be 'user' or 'role'"
        echo ""
        usage
    fi

    echo "=== IAM Policy Creation Script ==="
    echo "Attaching policies to ${principal_type}: ${principal_name}"
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
            if ! attach_policy "${policy_arn}" "${principal_type}" "${principal_name}"; then
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
