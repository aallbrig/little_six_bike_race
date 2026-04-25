extends Node2D
# Test Runner - Configures GUT to run our event-driven tests

@onready var _gut_control = $GutControl

func _ready():
	# Load default GUT config and customize for our tests
	_gut_control.load_config_file('res://addons/gut/.gutconfig.json')

	# Get config and customize
	var config = _gut_control.get_config()
	config.options.include_subdirs = true
	config.options.dirs = [
	    "res://test/core/",
	    "res://test/training/",
	    "res://test/race/",
	    "res://test/ui/",
	    "res://test/integration/",
	    "res://test/unit/"
	]
	config.options.should_exit = false
	config.options.should_exit_on_success = false
	config.options.log_level = 2  # INFO level
	config.options.double_strategy = 1  # SCRIPT_ONLY
	config.options.hide_orphans = false
	config.options.compact_mode = true

	# Connect to test completion
	var gut = _gut_control.get_gut()
	gut.end_run.connect(_on_tests_finished)

	# Auto-run tests when scene loads
	_gut_control.run_tests()

func _on_tests_finished():
	print("=== Test Suite Complete ===")
	var results = _gut_control.get_test_results()
	print("Passed: ", results.passing)
	print("Failed: ", results.failing)
	print("Pending: ", results.pending)
	print("Total: ", results._total)

	if results.failing > 0:
	    print("❌ Some tests failed")
	else:
	    print("✅ All tests passed")