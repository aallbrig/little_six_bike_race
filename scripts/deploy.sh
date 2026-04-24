#!/bin/bash

# deploy.sh - Full deployment to AWS
# Usage: ./scripts/deploy.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting full Little Six deployment to AWS"

# Step 1: Export web build
echo "📦 Step 1: Exporting Godot web build..."
if ! "$SCRIPT_DIR/export-web.sh"; then
    echo "❌ Web export failed"
    exit 1
fi

# Step 2: Build site
echo "🏗️  Step 2: Building static website..."
if ! "$SCRIPT_DIR/build-site.sh"; then
    echo "❌ Site build failed"
    exit 1
fi

# Step 3: Build SAM application
echo "🔨 Step 3: Building SAM application..."
if ! "$SCRIPT_DIR/sam-build.sh"; then
    echo "❌ SAM build failed"
    exit 1
fi

# Step 4: Deploy to AWS
echo "☁️  Step 4: Deploying to AWS..."
if ! "$SCRIPT_DIR/sam-deploy.sh"; then
    echo "❌ AWS deployment failed"
    exit 1
fi

echo "🎉 Full deployment completed successfully!"
echo "   Your Little Six game is now live on AWS!"