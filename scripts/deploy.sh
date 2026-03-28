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
    echo "Usage: $0 -e <environment> [-p] [-f]"
    echo "  -e: Environment (dev|staging|prod)"
    echo "  -p: Plan only (don't apply)"
    echo "  -f: Force apply without confirmation"
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

while getopts "e:pf" opt; do
    case $opt in
        e) ENVIRONMENT="$OPTARG" ;;
        p) PLAN_ONLY=true ;;
        f) FORCE=true ;;
        *) usage ;;
    esac
done

if [[ ! $ENVIRONMENT =~ ^(dev|staging|prod)$ ]]; then
    error "Invalid environment. Must be dev, staging, or prod"
fi

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    error "AWS credentials not configured or invalid"
fi

deploy() {
    local backend_config="${REPO_ROOT}/environments/${ENVIRONMENT}/backend.tfvars"
    local vars_file="${REPO_ROOT}/environments/${ENVIRONMENT}/terraform.tfvars"

    [[ -f "${backend_config}" ]] || error "Missing backend config: ${backend_config}"
    [[ -f "${vars_file}" ]] || error "Missing Terraform variables file: ${vars_file}"
    [[ -d "${TERRAFORM_DIR}" ]] || error "Missing Terraform directory: ${TERRAFORM_DIR}"

    log "Starting deployment for ${ENVIRONMENT} environment..."

    log "Initializing Terraform..."
    terraform -chdir="${TERRAFORM_DIR}" init -backend-config="${backend_config}" || error "Terraform init failed"

    terraform -chdir="${TERRAFORM_DIR}" workspace select "${ENVIRONMENT}" >/dev/null 2>&1 || \
        terraform -chdir="${TERRAFORM_DIR}" workspace new "${ENVIRONMENT}" >/dev/null || \
        error "Failed to select or create workspace ${ENVIRONMENT}"

    log "Checking Terraform formatting..."
    terraform -chdir="${TERRAFORM_DIR}" fmt -check -recursive || warn "Terraform formatting issues detected"

    log "Validating Terraform configuration..."
    terraform -chdir="${TERRAFORM_DIR}" validate || error "Terraform validation failed"

    log "Creating Terraform plan..."
    terraform -chdir="${TERRAFORM_DIR}" plan -var-file="${vars_file}" -out=tfplan || error "Terraform plan failed"

    if [[ $PLAN_ONLY == true ]]; then
        log "Plan completed successfully. Exiting as requested."
        exit 0
    fi

    if [[ $ENVIRONMENT == "prod" && $FORCE != true ]]; then
        warn "You are about to deploy to PRODUCTION!"
        read -r -p "Are you absolutely sure? Type 'yes' to confirm: " confirmation
        if [[ $confirmation != "yes" ]]; then
            error "Deployment aborted"
        fi
    fi

    log "Applying Terraform plan..."
    terraform -chdir="${TERRAFORM_DIR}" apply tfplan || error "Terraform apply failed"

    rm -f "${TERRAFORM_DIR}/tfplan"

    log "Deployment completed successfully!"
}

deploy || error "Deployment failed"

if [[ $PLAN_ONLY != true ]]; then
    log "Terraform outputs:"
    terraform -chdir="${TERRAFORM_DIR}" output
fi
