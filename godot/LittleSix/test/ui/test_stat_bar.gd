extends GutTest
# Test StatBar component - validates animated stat display UI

var stat_bar: StatBar

func before_each():
	stat_bar = StatBar.new()
	add_child(stat_bar)
	await get_tree().create_timer(0.1).wait

func after_each():
	stat_bar.queue_free()

func test_stat_bar_initial_display():
	# Given: StatBar with initial values
	stat_bar.stat_name = "Speed"
	stat_bar.value = 75
	stat_bar.bar_color = Color.BLUE

	# When: Component initializes
	await get_tree().create_timer(0.1).wait

	# Then: Should display correct values
	assert_eq(stat_bar.get_node("Label").text, "SPEED")
	assert_eq(stat_bar.get_node("ValueLabel").text, "75")
	assert_eq(stat_bar.get_node("ProgressBar").value, 75)

func test_stat_bar_value_change_animates():
	# Given: StatBar with initial value
	stat_bar.value = 50
	await get_tree().create_timer(0.1).wait
	assert_eq(stat_bar.get_node("ProgressBar").value, 50)

	# When: Value changes
	stat_bar.value = 80

	# Then: Should animate to new value
	await get_tree().create_timer(0.5).wait	 # Wait for animation
	assert_eq(stat_bar.get_node("ProgressBar").value, 80)
	assert_eq(stat_bar.get_node("ValueLabel").text, "80")

func test_stat_bar_value_clamping():
	# Given: StatBar ready

	# When: Set value above maximum
	stat_bar.value = 150

	# Then: Should clamp to 100
	assert_eq(stat_bar.value, 100)
	assert_eq(stat_bar.get_node("ValueLabel").text, "100")

	# When: Set value below minimum
	stat_bar.value = -10

	# Then: Should clamp to 0
	assert_eq(stat_bar.value, 0)
	assert_eq(stat_bar.get_node("ValueLabel").text, "0")

func test_stat_bar_no_animation_for_same_value():
	# Given: StatBar with value 50
	stat_bar.value = 50
	await get_tree().create_timer(0.1).wait
	var initial_bar_value = stat_bar.get_node("ProgressBar").value

	# When: Set same value
	stat_bar.value = 50

	# Then: Should not trigger animation (bar stays same)
	await get_tree().create_timer(0.1).wait
	assert_eq(stat_bar.get_node("ProgressBar").value, initial_bar_value)

func test_stat_bar_positive_delta_display():
	# Given: StatBar ready
	var initial_child_count = get_tree().root.get_child_count()

	# When: Value increases
	stat_bar.value = 60	 # from default 0

	# Then: Should show positive delta label
	await get_tree().create_timer(0.1).wait

	# Find delta label in scene root
	var delta_found = false
	for child in get_tree().root.get_children():
		if child is Label and child.text.begins_with("+"):
			delta_found = true
			assert_eq(child.text, "+60")
			assert_eq(child.modulate, Color.GREEN)
			break

	assert_true(delta_found, "Should create positive delta label")

func test_stat_bar_negative_delta_display():
	# Given: StatBar with high value
	stat_bar.value = 80

	# When: Value decreases
	stat_bar.value = 60

	# Then: Should show negative delta label
	await get_tree().create_timer(0.1).wait

	var delta_found = false
	for child in get_tree().root.get_children():
		if child is Label and child.text.begins_with("-"):
			delta_found = true
			assert_eq(child.text, "-20")
			assert_eq(child.modulate, Color.RED)
			break

	assert_true(delta_found, "Should create negative delta label")

func test_stat_bar_no_delta_for_zero_change():
	# Given: StatBar with value
	stat_bar.value = 50
	var initial_child_count = get_tree().root.get_child_count()

	# When: Value set to same value
	stat_bar.value = 50

	# Then: Should not create delta label
	await get_tree().create_timer(0.1).wait
	assert_eq(get_tree().root.get_child_count(), initial_child_count)

func test_stat_bar_name_change_updates_label():
	# Given: StatBar ready

	# When: Change stat name
	stat_bar.stat_name = "Endurance"

	# Then: Label should update to uppercase
	assert_eq(stat_bar.get_node("Label").text, "ENDURANCE")

func test_stat_bar_color_change_updates_bar():
	# Given: StatBar ready
	var new_color = Color.RED

	# When: Change bar color
	stat_bar.bar_color = new_color

	# Then: ProgressBar should use new color
	var style = stat_bar.get_node("ProgressBar").get_theme_stylebox("fill")
	if style and style.has_method("get_bg_color"):
		assert_eq(style.bg_color, new_color)

func test_stat_bar_delta_label_animation():
	# Given: StatBar ready

	# When: Create delta label by changing value
	stat_bar.value = 30

	# Then: Delta label should animate up and fade
	await get_tree().create_timer(0.1).wait

	var delta_label = null
	for child in get_tree().root.get_children():
		if child is Label and child.text == "+30":
			delta_label = child
			break

	assert_not_null(delta_label, "Should create delta label")

	# Record initial position
	var initial_pos = delta_label.global_position.y
	var initial_alpha = delta_label.modulate.a

	# Wait for animation
	await get_tree().create_timer(1.1).wait

	# Label should be freed by animation completion
	var still_exists = false
	for child in get_tree().root.get_children():
		if child == delta_label:
			still_exists = true
			break

	assert_false(still_exists, "Delta label should be freed after animation")

func test_stat_bar_initialization_values():
	# Given: StatBar with export values set

	# When: New StatBar created with default values
	var default_bar = StatBar.new()
	default_bar.stat_name = "Test"
	default_bar.value = 25
	default_bar.bar_color = Color.YELLOW
	add_child(default_bar)
	await get_tree().create_timer(0.1).wait

	# Then: Should initialize with provided values
	assert_eq(default_bar.get_node("Label").text, "TEST")
	assert_eq(default_bar.get_node("ValueLabel").text, "25")
	assert_eq(default_bar.get_node("ProgressBar").value, 25)

	default_bar.queue_free()