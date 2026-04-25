extends GutTest

class_name TestHUDMinimapIntegration

func test_hud_uses_minimap_component():
	# Given: HUD scene is loaded
	var hud_scene = load("res://scenes/ui/HUD.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	
	# When: HUD is ready
	await hud.ready
	
	# Then: HUD should have Minimap component instead of basic ColorRect
	var minimap_node = hud.get_node("RaceHUD/Minimap")
	assert_not_null(minimap_node, "HUD should have Minimap node")
	assert_true(minimap_node is Control, "Minimap should be a Control node")
	assert_true(minimap_node.has_method("update_rider_positions"), "Minimap should have update_rider_positions method")
	
	# And: Minimap should have proper structure
	var subviewport = minimap_node.get_node("SubViewportContainer/SubViewport")
	assert_not_null(subviewport, "Minimap should have SubViewport")
	
	var camera = subviewport.get_node("MinimapCamera")
	assert_not_null(camera, "Minimap should have camera")
	assert_eq(camera.projection, Camera3D.ProjectionType.PROJECTION_ORTHOGONAL, "Camera should be orthographic")
	
	# Cleanup
	hud.queue_free()

func test_hud_minimap_updates_rider_positions():
	# Given: HUD with Minimap component
	var hud_scene = load("res://scenes/ui/HUD.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	await hud.ready
	
	var minimap = hud.get_node("RaceHUD/Minimap")
	
	# When: Updating rider positions
	var test_positions = [
		Vector3(0, 0, 0),
		Vector3(10, 0, 20),
		Vector3(-20, 0, -30)
	]
	minimap.update_rider_positions(test_positions)
	
	# Then: Rider dots should be visible and positioned
	var rider_dots = minimap.get_node("MinimapOverlay/RiderDots")
	assert_eq(rider_dots.get_child_count(), 6, "Should have 6 rider dots")
	
	for i in range(3):
		var dot = rider_dots.get_child(i)
		assert_true(dot.visible, "Rider dot %d should be visible" % i)
	
	# Cleanup
	hud.queue_free()