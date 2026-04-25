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
    echo "   On newer systems, try: apt install docker-compose-plugin"
    exit 1
fi

cd "$PROJECT_ROOT/infra/localstack"

echo "🚀 Starting LocalStack services..."
echo "   - LocalStack API: http://localhost:4566"
echo "   - Services: Lambda, DynamoDB, API Gateway"
echo "   - Press Ctrl+C to stop"

# Try docker compose first (newer syntax), fallback to docker-compose
if docker compose version &> /dev/null; then
    exec docker compose up
else
    exec docker-compose up
fi