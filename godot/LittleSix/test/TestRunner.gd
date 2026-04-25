extends Node2D
# Test Runner - Configures GUT to run our event-driven tests

@onready var gut_control = $GutControl

func _ready():
    # Configure GUT
    gut_control.gut_config.include_subdirs = true
    gut_control.gut_config.dirs = [
        "res://test/core/",
        "res://test/training/",
        "res://test/race/",
        "res://test/ui/",
        "res://test/integration/"
    ]
    gut_control.gut_config.should_exit = false
    gut_control.gut_config.log_level = 2  # INFO level
    gut_control.gut_config.double_strategy = GutConfig.DOUBLE_STRATEGY.SCRIPT_ONLY
    gut_control.gut_config.hide_orphans = false
    
    # Connect to test completion
    gut_control.tests_finished.connect(_on_tests_finished)
    
    # Auto-run tests when scene loads
    gut_control.run_tests()

func _on_tests_finished():
    print("=== Test Suite Complete ===")
    var results = gut_control.get_test_results()
    print("Passed: ", results.passing)
    print("Failed: ", results.failing)
    print("Pending: ", results.pending)
    print("Total: ", results._total)
    
    if results.failing > 0:
        print("❌ Some tests failed")
    else:
        print("✅ All tests passed")