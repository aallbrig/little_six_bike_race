#!/bin/bash

# build-site.sh - Build the static website
# Usage: ./scripts/build-site.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

WEB_DIR="$PROJECT_ROOT/web"
DIST_DIR="$PROJECT_ROOT/dist/site"

echo "🏗️  Building Little Six static website"

if [ ! -d "$WEB_DIR" ]; then
    echo "❌ Error: Web source directory not found at $WEB_DIR"
    exit 1
fi

# Create dist directory
mkdir -p "$DIST_DIR"

# Copy web files
echo "📋 Copying web files..."
cp -r "$WEB_DIR"/* "$DIST_DIR"/

# Build Godot web export if it exists
GODOT_EXPORT_DIR="$PROJECT_ROOT/dist/web-game"
if [ -d "$GODOT_EXPORT_DIR" ]; then
    echo "🎮 Copying Godot web export..."
    mkdir -p "$DIST_DIR/game"
    cp -r "$GODOT_EXPORT_DIR"/* "$DIST_DIR/game"/
else
    echo "⚠️  Warning: Godot web export not found at $GODOT_EXPORT_DIR"
    echo "   Run 'make export-web' first to build the game"
fi

# Inject build version
BUILD_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")
echo "🏷️  Injecting build version: $BUILD_SHA"

# Update version in HTML files
for file in "$DIST_DIR"/*.html "$DIST_DIR/play/index.html"; do
    if [ -f "$file" ]; then
        sed -i.bak "s|<!-- BUILD:VERSION -->|$BUILD_SHA|g" "$file" && rm -f "${file}.bak"
    fi
done

# Validate HTML files if html-validate is available
if command -v html-validate &> /dev/null; then
    echo "🔍 Validating HTML files..."
    html-validate "$DIST_DIR"/*.html || echo "⚠️  HTML validation failed, but continuing..."
fi

echo "✅ Website build completed successfully"
echo "   Output: $DIST_DIR"