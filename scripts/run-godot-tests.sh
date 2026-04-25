#!/bin/bash
# Run GUT tests for Little Six

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/godot/LittleSix"

# Run Godot with the test scene
echo "Running tests with scene: res://test/TestRunner.tscn"
"$GODOT_BIN" --headless --scene "res://test/TestRunner.tscn" --quit-on-finish || true

echo "Tests completed."