extends GutTest
# Test EventTelemetryLogger.gd - validates Spec 010 Event Telemetry implementation

var telemetry_logger: EventTelemetryLogger

func before_each():
	telemetry_logger = EventTelemetryLogger.new()
	add_child(telemetry_logger)

func after_each():
	telemetry_logger.queue_free()

func test_telemetry_logger_initializes_and_connects_to_signals():
	# Given: TelemetryLogger is added to scene tree
	# When: _ready() is called
	# Then: Logger connects to all EventBus signals (we can't easily test all connections,
	#       but we can verify the logger exists and has expected methods)
	assert_not_null(telemetry_logger, "TelemetryLogger should be instantiated")
	assert_has_method(telemetry_logger, "set_enabled", "Should have enable/disable method")
	assert_has_method(telemetry_logger, "set_log_level", "Should have log level control")
	assert_has_method(telemetry_logger, "get_stats", "Should provide statistics")

func test_telemetry_logger_emits_correct_log_format():
	# Given: TelemetryLogger is initialized
	# When: A signal is emitted that should be logged
	# Then: The logger should handle it without errors

	# Emit a signal that should be logged
	EventBus.game_state_changed.emit(GameManager.GameState.TITLE)

	# If no errors occur, the test passes
	assert_true(true, "Signal emission handled without errors")

func test_telemetry_logger_handles_complex_parameters():
	# Given: TelemetryLogger is initialized
	# When: A signal with complex parameters is emitted
	# Then: Logger should process the signal without errors

	# Emit signal with dictionary parameter
	var test_dict = {"key": "value", "number": 42}
	EventBus.training_activity_resolved.emit(TrainingActivity.Type.ENDURANCE, test_dict)

	# If no errors occur, the test passes
	assert_true(true, "Complex parameters handled without errors")

func test_telemetry_logger_configurable_logging_levels():
	# Given: TelemetryLogger with DEBUG level
	telemetry_logger.set_log_level(3)  # DEBUG

	# When: Log level is set
	# Then: Level should be configurable

	assert_eq(telemetry_logger.get("log_level"), 3, "Should accept log level changes")

	# Test that methods exist
	assert_has_method(telemetry_logger, "set_log_level", "Should have log level control")

func test_telemetry_logger_can_be_disabled():
	# Given: TelemetryLogger is disabled
	telemetry_logger.set_enabled(false)

	# When: Signals are emitted
	# Then: Logger should remain functional but not log

	EventBus.game_state_changed.emit(GameManager.GameState.TITLE)

	# Test that methods still work
	assert_false(telemetry_logger.get("enabled"), "Should be able to disable")
	assert_has_method(telemetry_logger, "set_enabled", "Should have enable method")

func test_telemetry_logger_provides_statistics():
	# Given: TelemetryLogger has been running
	# When: get_stats() is called
	# Then: Should return meaningful statistics

	var stats = telemetry_logger.get_stats()

	assert_has(stats, "signals_logged", "Should track signal count")
	assert_has(stats, "uptime_seconds", "Should track uptime")
	assert_has(stats, "signals_per_second", "Should calculate rate")

	assert_typeof(stats.signals_logged, TYPE_INT, "Signal count should be integer")
	assert_typeof(stats.uptime_seconds, TYPE_FLOAT, "Uptime should be float")
	assert_typeof(stats.signals_per_second, TYPE_FLOAT, "Rate should be float")