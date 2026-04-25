extends GutTest
# Test RaceInputOverlay touch controls - validates mobile input handling

var input_overlay: RaceInputOverlay

func before_each():
    input_overlay = RaceInputOverlay.new()
    add_child(input_overlay)
    # Make visible for testing (normally invisible)
    input_overlay.modulate.a = 1.0
    # Set viewport size for zone calculations
    get_viewport().size = Vector2(1080, 1920)

func after_each():
    input_overlay.queue_free()

func test_touch_zones_detection():
    # Test zone detection logic
    var viewport_size = Vector2(1080, 1920)

    # Sprint zone: top-right quadrant
    var sprint_pos = Vector2(900, 240)  # x > 810, y < 480
    assert_true(input_overlay._is_in_sprint_zone(sprint_pos, viewport_size.x, viewport_size.y))

    # Brake zone: bottom-right
    var brake_pos = Vector2(900, 1600)  # x > 810, y > 1440
    assert_true(input_overlay._is_in_brake_zone(brake_pos, viewport_size.x, viewport_size.y))

    # Exchange zone: center-bottom
    var exchange_pos = Vector2(540, 1700)  # x: 432-648, y > 1536
    assert_true(input_overlay._is_in_exchange_zone(exchange_pos, viewport_size.x, viewport_size.y))

    # Steering zones: left vs right half
    var left_pos = Vector2(300, 960)  # x < 540
    var right_pos = Vector2(700, 960)  # x > 540

    # Note: _is_in_sprint_zone etc. are private, but we test the behavior via events

func test_touch_steering_left_emits_event():
    # Given: Input overlay ready
    watch_signals(EventBus)

    # When: Touch in left half of screen
    var touch_event = InputEventScreenTouch.new()
    touch_event.pressed = true
    touch_event.index = 1
    touch_event.position = Vector2(300, 960)  # Left side

    # Simulate input processing
    input_overlay._input(touch_event)

    # Then: Should emit steer left signal
    assert_signal_emitted(EventBus, "steer_input_changed")
    assert_signal_emitted_with_parameters(EventBus, "steer_input_changed", [-1.0])

func test_touch_steering_right_emits_event():
    # Given: Input overlay ready
    watch_signals(EventBus)

    # When: Touch in right half of screen (not in button zones)
    var touch_event = InputEventScreenTouch.new()
    touch_event.pressed = true
    touch_event.index = 1
    touch_event.position = Vector2(700, 960)  # Right side, middle

    input_overlay._input(touch_event)

    # Then: Should emit steer right signal
    assert_signal_emitted(EventBus, "steer_input_changed")
    assert_signal_emitted_with_parameters(EventBus, "steer_input_changed", [1.0])

func test_touch_sprint_button_emits_event():
    # Given: Input overlay ready
    watch_signals(EventBus)

    # When: Touch in sprint zone (top-right)
    var touch_event = InputEventScreenTouch.new()
    touch_event.pressed = true
    touch_event.index = 1
    touch_event.position = Vector2(900, 240)  # Sprint zone

    input_overlay._input(touch_event)

    # Then: Should emit sprint pressed signal
    assert_signal_emitted(EventBus, "sprint_button_pressed")
    assert_signal_emitted_with_parameters(EventBus, "sprint_button_pressed", [true])

func test_touch_brake_button_emits_event():
    # Given: Input overlay ready
    watch_signals(EventBus)

    # When: Touch in brake zone (bottom-right)
    var touch_event = InputEventScreenTouch.new()
    touch_event.pressed = true
    touch_event.index = 1
    touch_event.position = Vector2(900, 1600)  # Brake zone

    input_overlay._input(touch_event)

    # Then: Should emit brake pressed signal
    assert_signal_emitted(EventBus, "brake_button_pressed")
    assert_signal_emitted_with_parameters(EventBus, "brake_button_pressed", [true])

func test_touch_exchange_button_emits_event_when_visible():
    # Given: Input overlay with exchange visible
    watch_signals(EventBus)
    input_overlay.set_exchange_visible(true)

    # When: Touch in exchange zone (center-bottom)
    var touch_event = InputEventScreenTouch.new()
    touch_event.pressed = true
    touch_event.index = 1
    touch_event.position = Vector2(540, 1700)  # Exchange zone

    input_overlay._input(touch_event)

    # Then: Should emit exchange tapped signal
    assert_signal_emitted(EventBus, "exchange_button_tapped")

func test_touch_exchange_ignored_when_not_visible():
    # Given: Input overlay with exchange not visible
    watch_signals(EventBus)
    input_overlay.set_exchange_visible(false)

    # When: Touch in exchange zone
    var touch_event = InputEventScreenTouch.new()
    touch_event.pressed = true
    touch_event.index = 1
    touch_event.position = Vector2(540, 1700)  # Exchange zone

    input_overlay._input(touch_event)

    # Then: Should not emit exchange signal (treated as steering)
    assert_signal_not_emitted(EventBus, "exchange_button_tapped")
    # Should emit steer left (center position)
    assert_signal_emitted(EventBus, "steer_input_changed")

func test_touch_release_stops_steering():
    # Given: Active steering touch
    watch_signals(EventBus)

    # Press left
    var press_event = InputEventScreenTouch.new()
    press_event.pressed = true
    press_event.index = 1
    press_event.position = Vector2(300, 960)
    input_overlay._input(press_event)

    # When: Release touch
    var release_event = InputEventScreenTouch.new()
    release_event.pressed = false
    release_event.index = 1
    release_event.position = Vector2(300, 960)
    input_overlay._input(release_event)

    # Then: Should emit neutral steering (0.0)
    assert_signal_emitted_with_parameters(EventBus, "steer_input_changed", [0.0])

func test_touch_release_stops_buttons():
    # Given: Active sprint touch
    watch_signals(EventBus)

    # Press sprint
    var press_event = InputEventScreenTouch.new()
    press_event.pressed = true
    press_event.index = 1
    press_event.position = Vector2(900, 240)
    input_overlay._input(press_event)

    # When: Release touch
    var release_event = InputEventScreenTouch.new()
    release_event.pressed = false
    release_event.index = 1
    release_event.position = Vector2(900, 240)
    input_overlay._input(release_event)

    # Then: Should emit sprint released (false)
    assert_signal_emitted_with_parameters(EventBus, "sprint_button_pressed", [false])

func test_multiple_simultaneous_touches():
    # Given: Multiple touches active
    watch_signals(EventBus)

    # Touch 1: Left steering
    var touch1_press = InputEventScreenTouch.new()
    touch1_press.pressed = true
    touch1_press.index = 1
    touch1_press.position = Vector2(300, 960)
    input_overlay._input(touch1_press)

    # Touch 2: Sprint button
    var touch2_press = InputEventScreenTouch.new()
    touch2_press.pressed = true
    touch2_press.index = 2
    touch2_press.position = Vector2(900, 240)
    input_overlay._input(touch2_press)

    # Then: Both actions should be active
    assert_signal_emitted_with_parameters(EventBus, "steer_input_changed", [-1.0])
    assert_signal_emitted_with_parameters(EventBus, "sprint_button_pressed", [true])

    # When: Release touch 1
    var touch1_release = InputEventScreenTouch.new()
    touch1_release.pressed = false
    touch1_release.index = 1
    touch1_release.position = Vector2(300, 960)
    input_overlay._input(touch1_release)

    # Then: Steering should stop, sprint should continue
    assert_signal_emitted_with_parameters(EventBus, "steer_input_changed", [0.0])
    # Sprint should still be active (not released)