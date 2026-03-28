#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${REPO_ROOT}/src"

usage() {
    echo "Usage: $0 -e <environment> [-f]"
    echo "  -e: Environment (dev|staging|prod)"
    echo "  -f: Force deletion without confirmation"
    exit 1
}

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')]:${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]:${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]:${NC} $1"
    exit 1
}

while getopts "e:f" opt; do
    case $opt in
        e) ENVIRONMENT="$OPTARG" ;;
        f) FORCE=true ;;
        *) usage ;;
    esac
done

if [[ ! $ENVIRONMENT =~ ^(dev|staging|prod)$ ]]; then
    error "Invalid environment. Must be dev, staging, or prod"
fi

backend_config="${REPO_ROOT}/environments/${ENVIRONMENT}/backend.tfvars"
vars_file="${REPO_ROOT}/environments/${ENVIRONMENT}/terraform.tfvars"

[[ -f "${backend_config}" ]] || error "Missing backend config: ${backend_config}"
[[ -f "${vars_file}" ]] || error "Missing Terraform variables file: ${vars_file}"
[[ -d "${TERRAFORM_DIR}" ]] || error "Missing Terraform directory: ${TERRAFORM_DIR}"

if [[ $ENVIRONMENT == "prod" && $FORCE != true ]]; then
    warn "You are about to destroy PRODUCTION infrastructure!"
    read -r -p "Are you absolutely sure? Type 'yes' to confirm: " confirmation
    if [[ $confirmation != "yes" ]]; then
        error "Cleanup aborted"
    fi
fi

cleanup() {
cleanup() {
    log "Starting cleanup for ${ENVIRONMENT} environment..."

    log "Initializing Terraform..."
    terraform -chdir="${TERRAFORM_DIR}" init -backend-config="${backend_config}" || error "Terraform init failed"

    log "Switching to ${ENVIRONMENT} workspace..."
    terraform -chdir="${TERRAFORM_DIR}" workspace select "${ENVIRONMENT}" >/dev/null || error "Failed to switch workspace"

    log "Destroying infrastructure..."
    if [[ $FORCE == true ]]; then
        terraform -chdir="${TERRAFORM_DIR}" destroy -var-file="${vars_file}" -auto-approve || error "Terraform destroy failed"
    else
        terraform -chdir="${TERRAFORM_DIR}" destroy -var-file="${vars_file}" || error "Terraform destroy failed"
    fi

    log "Cleaning up local files..."
    rm -rf "${TERRAFORM_DIR}/.terraform" "${TERRAFORM_DIR}/terraform.tfstate" "${TERRAFORM_DIR}/terraform.tfstate.backup" || warn "Some files could not be removed"

    log "Cleanup completed successfully!"
}

cleanup || error "Cleanup failed"
