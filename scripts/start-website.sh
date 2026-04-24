#!/bin/bash

# start-website.sh - Start the marketing website server
# Usage: ./scripts/start-website.sh [port]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PORT="${1:-8000}"
WEB_DIR="$PROJECT_ROOT/web"

echo "🚀 Starting Little Six website server on http://localhost:$PORT"

if [ ! -d "$WEB_DIR" ]; then
    echo "❌ Error: Web directory not found at $WEB_DIR"
    echo "   Make sure you've run the website build process"
    exit 1
fi

cd "$WEB_DIR"

# Try Python 3 first, then fallback to Python, then Node.js serve
if command -v python3 &> /dev/null; then
    echo "📡 Using Python 3 HTTP server"
    python3 -m http.server "$PORT"
elif command -v python &> /dev/null; then
    echo "📡 Using Python HTTP server"
    python -m http.server "$PORT"
elif command -v npx &> /dev/null; then
    echo "📡 Using Node.js serve"
    npx serve -l "$PORT" ./
else
    echo "❌ Error: No suitable HTTP server found"
    echo "   Install Python 3 or Node.js with: apt install python3 || npm install -g serve"
    exit 1
fi