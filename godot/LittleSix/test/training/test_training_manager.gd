extends GutTest
# Test TrainingManager event-driven behavior - validates training system event flows

var training_manager: TrainingManager

func before_each():
    training_manager = TrainingManager.new()
    add_child(training_manager)
    # Reset any global state
    await get_tree().create_timer(0.1).wait

func after_each():
    training_manager.queue_free()

func test_training_day_started_signal_emitted():
    # Given: TrainingManager is initialized
    watch_signals(EventBus)

    # When: Training day is started (this happens automatically in _ready)
    await get_tree().create_timer(0.1).wait

    # Then: Should emit training_day_started signal
    assert_signal_emitted(EventBus, "training_day_started", "TrainingManager should emit day started signal")

func test_training_activity_choice_emits_signal():
    # Given: TrainingManager is ready
    watch_signals(EventBus)

    # When: An activity is selected
    var success = training_manager.select_activity(TrainingActivity.Type.ENDURANCE, 0)

    # Then: Should emit training_activity_chosen signal with correct parameters
    assert_true(success, "Activity selection should succeed")
    assert_signal_emitted(EventBus, "training_activity_chosen")
    assert_signal_emitted_with_parameters(EventBus, "training_activity_chosen", [TrainingActivity.Type.ENDURANCE, 0])

func test_training_day_completion_via_confirm():
    # Given: TrainingManager with selected activities
    watch_signals(EventBus)

    # Select some activities first
    training_manager.select_activity(TrainingActivity.Type.ENDURANCE, 0)
    training_manager.select_activity(TrainingActivity.Type.RECOVERY, 1)

    # When: Training day is confirmed (this resolves activities and may trigger random events)
    training_manager.confirm_training_day()

    # Then: Should emit training_activity_resolved signals for each activity
    assert_signal_emit_count(EventBus, "training_activity_resolved", 2, "Should emit resolution signal for each activity")

    # And should emit training_day_completed
    assert_signal_emitted(EventBus, "training_day_completed")

func test_training_invalid_activity_selection():
    # Given: TrainingManager is ready
    watch_signals(EventBus)

    # When: Try to select invalid activity (same activity twice)
    training_manager.select_activity(TrainingActivity.Type.ENDURANCE, 0)
    var success = training_manager.select_activity(TrainingActivity.Type.ENDURANCE, 1)

    # Then: Second selection should fail and not emit signal
    assert_false(success, "Should not allow duplicate activity selection")
    assert_signal_emit_count(EventBus, "training_activity_chosen", 1, "Should only emit for valid selection")

func test_training_fatigue_gating():
    # Given: TrainingManager with high fatigue racer
    # Note: This test requires setting up SaveManager with proper player data
    # For now, we'll test the basic selection logic

    watch_signals(EventBus)

    # When: Try to select intensive activity with high fatigue
    # This is a simplified test - full fatigue gating would need player data setup
    var success = training_manager.select_activity(TrainingActivity.Type.ENDURANCE, 0)

    # Then: Selection should work (basic case)
    assert_true(success, "Basic activity selection should work")
    assert_signal_emitted(EventBus, "training_activity_chosen")