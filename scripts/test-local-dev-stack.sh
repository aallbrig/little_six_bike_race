#!/bin/bash

# test-local-dev-stack.sh - Test the complete local development stack
# Usage: ./scripts/test-local-dev-stack.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🧪 Testing Little Six Local Development Stack"
echo "=========================================="

# Check if required tools are installed
echo "🔍 Checking dependencies..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm not found"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "❌ curl not found"
    exit 1
fi

echo "✅ Dependencies OK"

# Test matchmaking service
echo ""
echo "🎯 Testing matchmaking service..."

# Start matchmaking service in background
cd "$PROJECT_ROOT/infra/matchmaking"

if [ ! -d "node_modules" ]; then
    echo "📦 Installing matchmaking dependencies..."
    npm install
fi

echo "🚀 Starting matchmaking service..."
npm start &
MATCHMAKING_PID=$!

# Wait for service to start
echo "⏳ Waiting for matchmaking service..."
sleep 3

# Test health endpoint
echo "🏥 Testing health endpoint..."
if curl -f -s http://localhost:3001/health > /dev/null; then
    echo "✅ Matchmaking health check passed"
else
    echo "❌ Matchmaking health check failed"
    kill $MATCHMAKING_PID 2>/dev/null
    exit 1
fi

# Test matchmaking endpoint
echo "🎯 Testing matchmaking endpoint..."
MATCHMAKING_RESPONSE=$(curl -s -X POST http://localhost:3001/matchmaking/find \
    -H "Content-Type: application/json" \
    -d '{"race_type": "qualifying"}')

if echo "$MATCHMAKING_RESPONSE" | grep -q "serverUrl"; then
    echo "✅ Matchmaking API responded correctly"
    echo "   Response: $MATCHMAKING_RESPONSE"
else
    echo "❌ Matchmaking API failed"
    echo "   Response: $MATCHMAKING_RESPONSE"
    kill $MATCHMAKING_PID 2>/dev/null
    exit 1
fi

# Stop matchmaking service
echo "🛑 Stopping matchmaking service..."
kill $MATCHMAKING_PID 2>/dev/null
wait $MATCHMAKING_PID 2>/dev/null

echo ""
echo "✅ Local development stack test completed successfully!"
echo ""
echo "🎉 Ready to run: make dev"