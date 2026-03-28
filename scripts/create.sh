#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENVIRONMENT="${1:-}"
PLAN_ONLY="${2:-}"

if [[ -z "$ENVIRONMENT" ]]; then
    echo "Usage: $0 <environment> [--plan]"
    exit 1
fi

if [[ "$PLAN_ONLY" == "--plan" ]]; then
    exec "${SCRIPT_DIR}/deploy.sh" -e "$ENVIRONMENT" -p
fi

exec "${SCRIPT_DIR}/deploy.sh" -e "$ENVIRONMENT"
