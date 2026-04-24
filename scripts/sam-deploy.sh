#!/bin/bash

# sam-deploy.sh - Deploy SAM application to AWS
# Usage: ./scripts/sam-deploy.sh [stack-name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

STACK_NAME="${1:-little-six}"
TEMPLATE_FILE="$PROJECT_ROOT/infra/terraform/template.yaml"

echo "🚀 Deploying Little Six to AWS (Stack: $STACK_NAME)"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Error: SAM template not found at $TEMPLATE_FILE"
    echo "   Run 'make sam-build' first to build the application"
    exit 1
fi

if ! command -v sam &> /dev/null; then
    echo "❌ Error: AWS SAM CLI not found"
    echo "   Install with: pip install aws-sam-cli"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Error: AWS credentials not configured"
    echo "   Run: aws configure"
    exit 1
fi

cd "$PROJECT_ROOT"

echo "📦 Deploying SAM application..."
echo "   Stack Name: $STACK_NAME"
echo "   This may take several minutes..."

sam deploy \
    --template "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_IAM \
    --resolve-s3

echo "✅ Deployment completed successfully"