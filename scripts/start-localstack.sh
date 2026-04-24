#!/bin/bash

# start-localstack.sh - Start LocalStack for local AWS development
# Usage: ./scripts/start-localstack.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

DOCKER_COMPOSE_FILE="$PROJECT_ROOT/infra/localstack/docker-compose.yml"

echo "☁️  Starting LocalStack (local AWS simulation)"

if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "❌ Error: Docker Compose file not found at $DOCKER_COMPOSE_FILE"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker not found. Please install Docker."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose not found. Please install Docker Compose."
    exit 1
fi

cd "$PROJECT_ROOT/infra/localstack"

# Check if LocalStack is already running
if docker ps | grep -q localstack; then
    echo "⚠️  LocalStack is already running"
    echo "   Stop it first with: docker-compose down"
    exit 1
fi

echo "🚀 Starting LocalStack services..."
echo "   - LocalStack API: http://localhost:4566"
echo "   - Services: Lambda, DynamoDB, API Gateway"
echo "   - Press Ctrl+C to stop"

exec docker-compose up