extends GutTest
# Test SprintBar component - validates sprint energy gauge UI

var sprint_bar: SprintBar

func before_each():
	sprint_bar = SprintBar.new()
	add_child(sprint_bar)
	await get_tree().create_timer(0.1).wait

func after_each():
	sprint_bar.queue_free()

func test_sprint_bar_initial_state():
	# Given: SprintBar with default values

	# Then: Should start with full energy
	assert_eq(sprint_bar.sprint_energy, 100.0)
	assert_eq(sprint_bar.get_node("ProgressBar").value, 100.0)

func test_sprint_bar_energy_change_updates_bar():
	# Given: SprintBar ready

	# When: Set energy to 75%
	sprint_bar.sprint_energy = 75.0

	# Then: ProgressBar should reflect the change
	assert_eq(sprint_bar.sprint_energy, 75.0)
	assert_eq(sprint_bar.get_node("ProgressBar").value, 75.0)

func test_sprint_bar_energy_clamping():
	# Given: SprintBar ready

	# When: Set energy above maximum
	sprint_bar.sprint_energy = 150.0

	# Then: Should clamp to 100
	assert_eq(sprint_bar.sprint_energy, 100.0)
	assert_eq(sprint_bar.get_node("ProgressBar").value, 100.0)

	# When: Set energy below minimum
	sprint_bar.sprint_energy = -10.0

	# Then: Should clamp to 0
	assert_eq(sprint_bar.sprint_energy, 0.0)
	assert_eq(sprint_bar.get_node("ProgressBar").value, 0.0)

func test_sprint_bar_partial_energy():
	# Given: Various energy levels to test
	var test_values = [0.0, 25.5, 50.0, 77.3, 100.0]

	for value in test_values:
	    sprint_bar.sprint_energy = value

	    # Then: Should accurately reflect the value
	    assert_eq(sprint_bar.sprint_energy, value)
	    assert_eq(sprint_bar.get_node("ProgressBar").value, value)

func test_sprint_bar_float_precision():
	# Given: SprintBar ready

	# When: Set precise float values
	sprint_bar.sprint_energy = 33.333333
	sprint_bar.sprint_energy = 66.666666

	# Then: Should handle float precision
	assert_almost_eq(sprint_bar.sprint_energy, 33.333333, 0.001)
	assert_almost_eq(sprint_bar.get_node("ProgressBar").value, 33.333333, 0.001)

func test_sprint_bar_range_validation():
	# Test that the component handles edge cases
	var edge_cases = [-999, -1, 0, 1, 99, 100, 101, 999]

	for value in edge_cases:
	    sprint_bar.sprint_energy = value

	    # Should always be between 0 and 100
	    assert_gte(sprint_bar.sprint_energy, 0.0, "Energy should never be negative")
	    assert_lte(sprint_bar.sprint_energy, 100.0, "Energy should never exceed 100")
	    assert_eq(sprint_bar.get_node("ProgressBar").value, sprint_bar.sprint_energy, "Bar should match energy value")

func test_sprint_bar_initialization_with_custom_value():
	# Given: New SprintBar with custom initial energy
	var custom_bar = SprintBar.new()
	custom_bar.sprint_energy = 42.0
	add_child(custom_bar)
	await get_tree().create_timer(0.1).wait

	# Then: Should initialize with provided value
	assert_eq(custom_bar.sprint_energy, 42.0)
	assert_eq(custom_bar.get_node("ProgressBar").value, 42.0)

	custom_bar.queue_free()

func test_sprint_bar_progress_bar_properties():
	# Given: SprintBar ready

	# Then: ProgressBar should have appropriate default properties
	var progress_bar = sprint_bar.get_node("ProgressBar")
	assert_not_null(progress_bar)
	assert_eq(progress_bar.min_value, 0)
	assert_eq(progress_bar.max_value, 100)
	assert_eq(progress_bar.value, sprint_bar.sprint_energy)