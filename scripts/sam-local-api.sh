#!/bin/bash

# sam-local-api.sh - Start SAM API locally for testing
# Usage: ./scripts/sam-local-api.sh [port]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PORT="${1:-3000}"
TEMPLATE_FILE="$PROJECT_ROOT/infra/terraform/template.yaml"

echo "🌐 Starting SAM local API on port $PORT"

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

echo "🚀 Starting SAM local API..."
echo "   Local API: http://localhost:$PORT"
echo "   Press Ctrl+C to stop"

sam local start-api --template "${TEMPLATE_FILE:-infra/terraform/template.yaml}" --port "$PORT"