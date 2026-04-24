#!/bin/bash

# open-godot-editor.sh - Open the Little Six project in Godot editor
# Usage: ./scripts/open-godot-editor.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

GODOT_PROJECT_DIR="$PROJECT_ROOT/godot/LittleSix"
GODOT_PROJECT_FILE="$GODOT_PROJECT_DIR/project.godot"

echo "🎨 Opening Little Six in Godot editor"

if [ ! -f "$GODOT_PROJECT_FILE" ]; then
    echo "❌ Error: Godot project file not found at $GODOT_PROJECT_FILE"
    exit 1
fi

if ! command -v godot &> /dev/null; then
    echo "❌ Error: Godot executable not found in PATH"
    echo "   Make sure Godot is installed and available in your PATH"
    exit 1
fi

cd "$PROJECT_ROOT"
exec godot --path "$GODOT_PROJECT_DIR" --editor