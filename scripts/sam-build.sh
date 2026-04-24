#!/bin/bash

# sam-build.sh - Build the SAM application
# Usage: ./scripts/sam-build.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

TEMPLATE_FILE="$PROJECT_ROOT/infra/terraform/template.yaml"

echo "🔨 Building SAM application"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "⚠️  Warning: SAM template not found at $TEMPLATE_FILE"
    echo "   This will be created when Spec 006 is implemented"
    echo "   Using default template path for now..."
fi

if ! command -v sam &> /dev/null; then
    echo "❌ Error: AWS SAM CLI not found"
    echo "   Install with: pip install aws-sam-cli"
    exit 1
fi

cd "$PROJECT_ROOT"

echo "📦 Building SAM application..."
sam build --template "${TEMPLATE_FILE:-infra/terraform/template.yaml}" --build-dir .aws-sam/build

echo "✅ SAM build completed successfully"