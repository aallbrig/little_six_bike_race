#!/bin/bash

# export-web.sh - Export Godot game for web
# Usage: ./scripts/export-web.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

GODOT_PROJECT_DIR="$PROJECT_ROOT/godot/LittleSix"
GODOT_PROJECT_FILE="$GODOT_PROJECT_DIR/project.godot"
EXPORT_DIR="$PROJECT_ROOT/dist/web-game"

echo "🌐 Exporting Little Six for web"

if [ ! -f "$GODOT_PROJECT_FILE" ]; then
    echo "❌ Error: Godot project file not found at $GODOT_PROJECT_FILE"
    exit 1
fi

if ! command -v godot &> /dev/null; then
    echo "❌ Error: Godot executable not found in PATH"
    echo "   Make sure Godot is installed and available in your PATH"
    exit 1
fi

# Create export directory
mkdir -p "$EXPORT_DIR"

cd "$PROJECT_ROOT"

echo "📦 Exporting Godot project for HTML5..."
echo "   This may take a minute..."

# Export for HTML5
godot --path "$GODOT_PROJECT_DIR" --export-release "HTML5" "$EXPORT_DIR/index.html"

if [ ! -f "$EXPORT_DIR/index.html" ]; then
    echo "❌ Error: Export failed - no output file generated"
    exit 1
fi

echo "✅ Web export completed successfully"
echo "   Output: $EXPORT_DIR"
echo "   Main file: $EXPORT_DIR/index.html"