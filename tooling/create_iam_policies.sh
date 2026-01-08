#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODULES_DIR="${PROJECT_ROOT}/modules"
POLICY_NAME_PREFIX="terraform-profile-website"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    print_info "AWS CLI found: $(aws --version)"
}

# Function to check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured or invalid."
        exit 1
    fi
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local user_arn=$(aws sts get-caller-identity --query Arn --output text)
    print_info "Using AWS Account: ${account_id}"
    print_info "Identity: ${user_arn}"
}

# Function to create or update IAM policy
create_or_update_policy() {
    local module_name=$1
    local policy_file=$2
    local policy_name="${POLICY_NAME_PREFIX}-${module_name}"
    local description="IAM policy to manage ${module_name} related resources from terraform to deploy the profile website infrastructure"
    
    print_info "Processing module: ${module_name}"
    
    # Check if policy file exists
    if [[ ! -f "${policy_file}" ]]; then
        print_error "Policy file not found: ${policy_file}"
        return 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "${policy_file}" 2>/dev/null; then
        print_error "Invalid JSON in policy file: ${policy_file}"
        return 1
    fi
    
    # Check if policy already exists
    local policy_arn=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${policy_name}'].Arn" --output text 2>/dev/null || true)
    
    if [[ -n "${policy_arn}" ]]; then
        print_warning "Policy '${policy_name}' already exists (ARN: ${policy_arn})"
        
        # Get current default version
        local current_version=$(aws iam get-policy --policy-arn "${policy_arn}" --query 'Policy.DefaultVersionId' --output text)
        print_info "Current version: ${current_version}"
        
        # List all versions and count them
        local version_count=$(aws iam list-policy-versions --policy-arn "${policy_arn}" --query 'Versions | length(@)' --output text)
        print_info "Existing versions: ${version_count}/5"
        
        # If we have 5 versions, delete the oldest non-default version
        if [[ ${version_count} -eq 5 ]]; then
            print_warning "Maximum versions (5) reached. Deleting oldest non-default version..."
            local oldest_version=$(aws iam list-policy-versions --policy-arn "${policy_arn}" \
                --query 'Versions[?IsDefaultVersion==`false`] | sort_by(@, &CreateDate) | [0].VersionId' --output text)
            
            if [[ -n "${oldest_version}" ]]; then
                aws iam delete-policy-version --policy-arn "${policy_arn}" --version-id "${oldest_version}"
                print_info "Deleted version: ${oldest_version}"
            fi
        fi
        
        # Create new policy version
        print_info "Creating new policy version..."
        local new_version=$(aws iam create-policy-version \
            --policy-arn "${policy_arn}" \
            --policy-document "file://${policy_file}" \
            --set-as-default \
            --query 'PolicyVersion.VersionId' \
            --output text)
        
        print_info "✓ Updated policy '${policy_name}' with new version: ${new_version}"
    else
        print_info "Creating new policy '${policy_name}'..."
        policy_arn=$(aws iam create-policy \
            --policy-name "${policy_name}" \
            --policy-document "file://${policy_file}" \
            --description "${description}" \
            --query 'Policy.Arn' \
            --output text)
        
        print_info "✓ Created policy '${policy_name}' (ARN: ${policy_arn})"
    fi
    
    echo ""
    return 0
}

# Function to attach policy to a role or user (optional)
attach_policy() {
    local policy_arn=$1
    local attach_to=$2
    local attach_type=$3  # "role" or "user"
    
    if [[ "${attach_type}" == "role" ]]; then
        aws iam attach-role-policy --role-name "${attach_to}" --policy-arn "${policy_arn}"
        print_info "✓ Attached policy to role: ${attach_to}"
    elif [[ "${attach_type}" == "user" ]]; then
        aws iam attach-user-policy --user-name "${attach_to}" --policy-arn "${policy_arn}"
        print_info "✓ Attached policy to user: ${attach_to}"
    fi
}

# Main execution
main() {
    print_info "=== IAM Policy Creation Script ==="
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
        print_error "No iam-policy.json files found in ${MODULES_DIR}"
        exit 1
    fi
    
    print_info "Found ${#policy_files[@]} policy file(s):"
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
        
        if create_or_update_policy "${module_name}" "${policy_file}"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    # Summary
    echo ""
    print_info "=== Summary ==="
    print_info "Successfully processed: ${success_count}"
    if [[ ${fail_count} -gt 0 ]]; then
        print_error "Failed: ${fail_count}"
        exit 1
    fi
    
    print_info "✓ All policies created/updated successfully!"
    echo ""
    print_info "Note: Policies are created but not attached to any role or user."
    print_info "To attach policies, use: aws iam attach-role-policy --role-name <ROLE> --policy-arn <ARN>"
}

# Run main function
main "$@"
