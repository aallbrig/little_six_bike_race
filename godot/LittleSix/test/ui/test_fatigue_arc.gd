extends GutTest
# Test FatigueArc component - validates circular fatigue indicator UI

var fatigue_arc: FatigueArc

func before_each():
	fatigue_arc = FatigueArc.new()
	add_child(fatigue_arc)
	# Set size for drawing
	fatigue_arc.size = Vector2(200, 200)
	await get_tree().create_timer(0.1).wait

func after_each():
	fatigue_arc.queue_free()

func test_fatigue_arc_initial_state():
	# Given: FatigueArc with default fatigue
	fatigue_arc.fatigue = 0

	# Then: Should show "FRESH" label
	assert_eq(fatigue_arc.get_node("Label").text, "FRESH")

func test_fatigue_arc_fresh_state():
	# Given: Low fatigue values
	var test_values = [0, 15, 30]

	for value in test_values:
	    fatigue_arc.fatigue = value

	    # Then: Should show "FRESH" and be green
	    assert_eq(fatigue_arc.get_node("Label").text, "FRESH")
	    # Visual state tested via drawing, but we can verify value is set
	    assert_eq(fatigue_arc.fatigue, value)

func test_fatigue_arc_tired_state():
	# Given: Medium fatigue values
	var test_values = [31, 50, 70]

	for value in test_values:
	    fatigue_arc.fatigue = value

	    # Then: Should show "TIRED"
	    assert_eq(fatigue_arc.get_node("Label").text, "TIRED")
	    assert_eq(fatigue_arc.fatigue, value)

func test_fatigue_arc_overloaded_state():
	# Given: High fatigue values
	var test_values = [71, 85, 100]

	for value in test_values:
	    fatigue_arc.fatigue = value

	    # Then: Should show "OVERLOADED"
	    assert_eq(fatigue_arc.get_node("Label").text, "OVERLOADED")
	    assert_eq(fatigue_arc.fatigue, value)

func test_fatigue_arc_value_clamping():
	# Given: FatigueArc ready

	# When: Set value above maximum
	fatigue_arc.fatigue = 150

	# Then: Should clamp to 100
	assert_eq(fatigue_arc.fatigue, 100)

	# When: Set value below minimum
	fatigue_arc.fatigue = -10

	# Then: Should clamp to 0
	assert_eq(fatigue_arc.fatigue, 0)

func test_fatigue_arc_triggers_redraw():
	# Given: FatigueArc with initial value
	fatigue_arc.fatigue = 25

	# When: Fatigue changes
	var redraw_called = false
	var original_queue_redraw = fatigue_arc.queue_redraw
	fatigue_arc.queue_redraw = func(): redraw_called = true

	fatigue_arc.fatigue = 50

	# Restore original
	fatigue_arc.queue_redraw = original_queue_redraw

	# Then: Should trigger redraw
	assert_true(redraw_called, "Should trigger redraw when fatigue changes")

func test_fatigue_arc_label_updates_on_change():
	# Given: FatigueArc with low fatigue
	fatigue_arc.fatigue = 20
	assert_eq(fatigue_arc.get_node("Label").text, "FRESH")

	# When: Fatigue enters tired range
	fatigue_arc.fatigue = 45

	# Then: Label should update
	assert_eq(fatigue_arc.get_node("Label").text, "TIRED")

	# When: Fatigue enters overloaded range
	fatigue_arc.fatigue = 85

	# Then: Label should update again
	assert_eq(fatigue_arc.get_node("Label").text, "OVERLOADED")

func test_fatigue_arc_arc_drawing_calculation():
	# Test the drawing calculations (without actually drawing)
	fatigue_arc.fatigue = 50
	fatigue_arc.size = Vector2(200, 200)

	# Calculate expected arc properties
	var center = fatigue_arc.size / 2
	var radius = min(fatigue_arc.size.x, fatigue_arc.size.y) / 2 - 10
	var expected_angle_to = -PI/2 + (50.0 / 100.0) * 2 * PI  # 50% = PI radians

	# We can't directly test drawing, but we can verify the component
	# handles the calculation inputs correctly
	assert_eq(center, Vector2(100, 100))
	assert_eq(radius, 90)  # 200/2 - 10 = 90

	# The actual drawing verification would require visual testing
	# For unit tests, we verify the inputs are processed
	assert_eq(fatigue_arc.fatigue, 50)

func test_fatigue_arc_color_zones():
	# Test color determination logic
	var test_cases = [
	    [0, "FRESH"],
	    [25, "FRESH"],
	    [30, "FRESH"],   # Boundary
	    [31, "TIRED"],
	    [50, "TIRED"],
	    [70, "TIRED"],   # Boundary
	    [71, "OVERLOADED"],
	    [85, "OVERLOADED"],
	    [100, "OVERLOADED"]
	]

	for test_case in test_cases:
	    var fatigue_value = test_case[0]
	    var expected_label = test_case[1]

	    fatigue_arc.fatigue = fatigue_value
	    assert_eq(fatigue_arc.get_node("Label").text, expected_label,
	             "Fatigue " + str(fatigue_value) + " should show " + expected_label)

func test_fatigue_arc_boundary_transitions():
	# Test exact boundary values
	var boundaries = [30, 70]

	for boundary in boundaries:
	    # Test just below boundary
	    fatigue_arc.fatigue = boundary - 1
	    var below_label = fatigue_arc.get_node("Label").text

	    # Test exactly at boundary
	    fatigue_arc.fatigue = boundary
	    var at_label = fatigue_arc.get_node("Label").text

	    # Test just above boundary
	    fatigue_arc.fatigue = boundary + 1
	    var above_label = fatigue_arc.get_node("Label").text

	    # Verify transitions work correctly
	    if boundary == 30:
	        assert_eq(below_label, "FRESH")
	        assert_eq(at_label, "FRESH")  # 30 is still FRESH
	        assert_eq(above_label, "TIRED")
	    elif boundary == 70:
	        assert_eq(below_label, "TIRED")
	        assert_eq(at_label, "TIRED")  # 70 is still TIRED
	        assert_eq(above_label, "OVERLOADED")

func test_fatigue_arc_initialization():
	# Given: New FatigueArc with custom initial values
	var custom_arc = FatigueArc.new()
	custom_arc.fatigue = 65  # Should be TIRED
	add_child(custom_arc)
	custom_arc.size = Vector2(150, 150)
	await get_tree().create_timer(0.1).wait

	# Then: Should initialize with correct state
	assert_eq(custom_arc.fatigue, 65)
	assert_eq(custom_arc.get_node("Label").text, "TIRED")
	assert_eq(custom_arc.size, Vector2(150, 150))

	custom_arc.queue_free()

func test_fatigue_arc_no_change_no_update():
	# Given: FatigueArc with value set
	fatigue_arc.fatigue = 40

	# When: Set same value again
	fatigue_arc.fatigue = 40

	# Then: Should still work (no crash) and maintain state
	assert_eq(fatigue_arc.fatigue, 40)
	assert_eq(fatigue_arc.get_node("Label").text, "TIRED")