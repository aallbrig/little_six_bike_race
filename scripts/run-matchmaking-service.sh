#!/bin/bash

# run-matchmaking-service.sh - Run the matchmaking service locally
# Usage: ./scripts/run-matchmaking-service.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

MATCHMAKING_DIR="$PROJECT_ROOT/infra/matchmaking"
PACKAGE_JSON="$MATCHMAKING_DIR/package.json"

echo "🎯 Starting Little Six matchmaking service"

if [ ! -f "$PACKAGE_JSON" ]; then
    echo "❌ Error: Package.json not found at $PACKAGE_JSON"
    exit 1
fi

if ! command -v node &> /dev/null && ! command -v npm &> /dev/null; then
    echo "❌ Error: Node.js/npm not found. Please install Node.js."
    exit 1
fi

cd "$MATCHMAKING_DIR"

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo "🚀 Starting matchmaking service..."
echo "   Make sure LocalStack is running first"
exec npm run dev