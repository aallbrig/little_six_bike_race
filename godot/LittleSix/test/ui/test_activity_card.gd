extends GutTest
# Test ActivityCard component - validates training activity selection UI

var activity_card: ActivityCard

func before_each():
	activity_card = ActivityCard.new()
	add_child(activity_card)
	# Wait for _ready to complete
	await get_tree().create_timer(0.1).wait

func after_each():
	activity_card.queue_free()

func test_activity_card_displays_correct_info():
	# Given: ActivityCard with specific activity type
	activity_card.activity_type = TrainingActivity.Type.ENDURANCE

	# When: Card updates display
	await get_tree().create_timer(0.1).wait

	# Then: Should display correct name and effects
	assert_eq(activity_card.get_node("VBoxContainer/NameLabel").text, "Long Endurance Run")
	var effect_text = activity_card.get_node("VBoxContainer/EffectLabel").text
	assert_string_contains(effect_text, "Endurance")
	assert_string_contains(effect_text, "Fatigue")

func test_activity_card_emits_signal_on_click():
	# Given: ActivityCard ready
	watch_signals(activity_card)
	activity_card.activity_type = TrainingActivity.Type.SPRINT_INTERVALS

	# When: Simulate mouse click
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = Vector2(50, 50)

	activity_card._on_gui_input(click_event)

	# Then: Should emit card_tapped signal with activity type
	assert_signal_emitted(activity_card, "card_tapped")
	assert_signal_emitted_with_parameters(activity_card, "card_tapped", [TrainingActivity.Type.SPRINT_INTERVALS])

func test_activity_card_ignores_click_when_disabled():
	# Given: Disabled ActivityCard
	watch_signals(activity_card)
	activity_card.is_disabled = true
	activity_card.activity_type = TrainingActivity.Type.ENDURANCE

	# When: Simulate mouse click on disabled card
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = Vector2(50, 50)

	activity_card._on_gui_input(click_event)

	# Then: Should not emit signal
	assert_signal_not_emitted(activity_card, "card_tapped")

func test_activity_card_visual_feedback_when_selected():
	# Given: ActivityCard not selected
	activity_card.is_selected = false

	# When: Set selected
	activity_card.is_selected = true

	# Then: Should have custom border style
	var style = activity_card.get_theme_stylebox("panel")
	assert_not_null(style, "Should have custom panel style")
	assert_eq(style.border_width_left, 3, "Should have border")
	assert_eq(style.bg_color, Color(0.701961, 0.105882, 0.105882, 1), "Should have crimson background")

func test_activity_card_visual_feedback_when_deselected():
	# Given: ActivityCard selected
	activity_card.is_selected = true

	# When: Deselect
	activity_card.is_selected = false

	# Then: Should not have custom border style
	var style = activity_card.get_theme_stylebox("panel")
	assert_null(style, "Should not have custom panel style when deselected")

func test_activity_card_disabled_visual_state():
	# Given: ActivityCard enabled
	activity_card.is_disabled = false

	# When: Disable
	activity_card.is_disabled = true

	# Then: Should be grayed out
	assert_eq(activity_card.modulate, Color.GRAY, "Disabled card should be gray")

func test_activity_card_enabled_visual_state():
	# Given: ActivityCard disabled
	activity_card.is_disabled = true

	# When: Enable
	activity_card.is_disabled = false

	# Then: Should be normal color
	assert_eq(activity_card.modulate, Color.WHITE, "Enabled card should be white")

func test_activity_card_activity_type_change_updates_display():
	# Given: ActivityCard with one activity
	activity_card.activity_type = TrainingActivity.Type.SPRINT_INTERVALS
	await get_tree().create_timer(0.1).wait

	var initial_text = activity_card.get_node("VBoxContainer/NameLabel").text

	# When: Change activity type
	activity_card.activity_type = TrainingActivity.Type.RECOVERY_SPIN
	await get_tree().create_timer(0.1).wait

	# Then: Display should update
	var new_text = activity_card.get_node("VBoxContainer/NameLabel").text
	assert_ne(initial_text, new_text, "Display should change when activity type changes")
	assert_eq(new_text, "Recovery Spin", "Should show new activity name")

func test_activity_card_effect_text_formatting():
	# Given: ActivityCard with multiple effects
	activity_card.activity_type = TrainingActivity.Type.TEMPO_RUN

	# When: Display updates
	await get_tree().create_timer(0.1).wait

	# Then: Effect text should be properly formatted
	var effect_label = activity_card.get_node("VBoxContainer/EffectLabel")
	var effect_text = effect_label.text

	# Tempo run should have speed and endurance effects
	assert_string_contains(effect_text, "Speed", "Should show speed effect")
	assert_string_contains(effect_text, "Endurance", "Should show endurance effect")
	assert_string_contains(effect_text, "Fatigue", "Should show fatigue cost")

func test_activity_card_signal_parameter_validation():
	# Given: ActivityCard with specific activity
	watch_signals(activity_card)
	var test_activity = TrainingActivity.Type.ENDURANCE
	activity_card.activity_type = test_activity

	# When: Click the card
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	activity_card._on_gui_input(click_event)

	# Then: Signal should contain the exact activity type
	var signal_params = get_signal_parameters(activity_card, "card_tapped")
	assert_eq(signal_params.size(), 1, "Should have one parameter")
	assert_eq(signal_params[0], test_activity, "Parameter should match activity type")