#!/bin/bash

# run-godot-game.sh - Run the Little Six game
# Usage: ./scripts/run-godot-game.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

GODOT_PROJECT_DIR="$PROJECT_ROOT/godot/LittleSix"
GODOT_PROJECT_FILE="$GODOT_PROJECT_DIR/project.godot"

echo "🎮 Starting Little Six game"

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
exec godot --path "$GODOT_PROJECT_DIR"