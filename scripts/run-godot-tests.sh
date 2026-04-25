#!/bin/bash
# Simple test runner using GUT command line interface

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/godot/LittleSix"

# Use GUT's command line testing
echo "Running GUT tests via command line..."

# Try to run tests directly using GUT's gut.gd script
if ! command -v godot &> /dev/null; then
    echo "❌ Error: Godot executable not found in PATH"
    exit 1
fi

# Run tests using a simpler approach - create a minimal test scene that loads and runs tests
cat > test_minimal.gd << 'EOF'
extends SceneTree

func _init():
    # Load GUT
    var gut_script = load("res://addons/gut/addons/gut/gut.gd")
    if gut_script == null:
        print("ERROR: Could not load GUT script")
        quit(1)
        return
    
    var gut = gut_script.new()
    gut.logger = gut.logger.new()
    
    # Configure GUT
    gut.log_level = 2
    gut.include_subdirs = true
    gut.dirs = ["res://test/core/", "res://test/training/"]
    gut.double_strategy = gut.DOUBLE_STRATEGY.SCRIPT_ONLY
    
    # Connect signals
    gut.end_run.connect(_on_tests_finished)
    
    # Add to scene tree and run
    var root = get_root()
    root.add_child(gut)
    
    gut.test_scripts()

func _on_tests_finished():
    var results = gut.get_test_results()
    print("\n=== Test Results ===")
    print("Passed: ", results.passing)
    print("Failed: ", results.failing)
    print("Total: ", results._total)
    
    if results.failing > 0:
        print("❌ Some tests failed")
        quit(1)
    else:
        print("✅ All tests passed")
        quit(0)
EOF

# Run the minimal test script
godot --headless --script test_minimal.gd --quit-on-finish || true

# Clean up
rm -f test_minimal.gd

echo "Test run completed."