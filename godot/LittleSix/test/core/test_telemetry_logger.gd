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
    # Then: The logger should handle it (we'll test with a mock signal)
    
    # Watch for print_rich calls (since that's how the logger outputs)
    var original_print_rich = print_rich
    var logged_messages = []
    print_rich = func(msg): logged_messages.append(msg)
    
    # Emit a signal that should be logged
    EventBus.game_state_changed.emit(GameManager.GameState.TITLE)
    
    # Restore original function
    print_rich = original_print_rich
    
    # Verify a message was logged (exact format may vary)
    assert_gt(logged_messages.size(), 0, "Should log when game_state_changed is emitted")
    assert_string_contains(logged_messages[0], "[TELEMETRY]", "Should use telemetry prefix")

func test_telemetry_logger_handles_complex_parameters():
    # Given: TelemetryLogger is initialized
    # When: A signal with complex parameters is emitted
    # Then: Logger should serialize parameters correctly
    
    var original_print_rich = print_rich
    var logged_messages = []
    print_rich = func(msg): logged_messages.append(msg)
    
    # Emit signal with dictionary parameter
    var test_dict = {"key": "value", "number": 42}
    EventBus.training_activity_resolved.emit(TrainingActivity.Type.ENDURANCE, test_dict)
    
    print_rich = original_print_rich
    
    # Verify complex parameter is logged
    assert_gt(logged_messages.size(), 0, "Should log activity resolved signal")
    assert_string_contains(logged_messages[0], "ENDURANCE", "Should include enum value")
    # Dictionary serialization is handled internally, we just verify signal is processed

func test_telemetry_logger_configurable_logging_levels():
    # Given: TelemetryLogger with DEBUG level
    telemetry_logger.set_log_level(3)  # DEBUG
    
    # When: Various signals are emitted
    # Then: All signals should be logged at DEBUG level
    
    var original_print_rich = print_rich
    var logged_messages = []
    print_rich = func(msg): logged_messages.append(msg)
    
    # Emit a high-frequency signal that might be filtered at lower levels
    EventBus.steer_input_changed.emit(0.5)  # This should only log at DEBUG level
    
    print_rich = original_print_rich
    
    # At DEBUG level, steer input should be logged
    assert_gt(logged_messages.size(), 0, "DEBUG level should log steer input")

func test_telemetry_logger_can_be_disabled():
    # Given: TelemetryLogger is disabled
    telemetry_logger.set_enabled(false)
    
    # When: Signals are emitted
    # Then: No logging should occur
    
    var original_print_rich = print_rich
    var logged_messages = []
    print_rich = func(msg): logged_messages.append(msg)
    
    EventBus.game_state_changed.emit(GameManager.GameState.TITLE)
    
    print_rich = original_print_rich
    
    # Should not log when disabled
    assert_eq(logged_messages.size(), 0, "Disabled logger should not log messages")

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