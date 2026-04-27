extends Node
class_name SafeAreaManager

# Utility for handling safe areas (notch, home indicator) on mobile devices

static func get_safe_area() -> Rect2i:
	return DisplayServer.get_display_safe_area()

static func get_safe_margins() -> Dictionary:
	var safe_area = get_safe_area()
	var screen_size = DisplayServer.window_get_size()

	return {
		"top": safe_area.position.y,
		"bottom": screen_size.y - (safe_area.position.y + safe_area.size.y),
		"left": safe_area.position.x,
		"right": screen_size.x - (safe_area.position.x + safe_area.size.x)
	}

static func apply_safe_area_to_container(container: Control, include_top: bool = true, include_bottom: bool = true) -> void:
	var margins = get_safe_margins()

	if include_top:
		container.add_theme_constant_override("margin_top", margins.top + 8)
	if include_bottom:
		container.add_theme_constant_override("margin_bottom", margins.bottom + 8)

	container.add_theme_constant_override("margin_left", margins.left + 8)
	container.add_theme_constant_override("margin_right", margins.right + 8)

static func is_safe_area_supported() -> bool:
	# Check if we're on a platform that supports safe areas
	var platform = OS.get_name()
	return platform == "iOS" or platform == "Android"

static func get_effective_viewport_size() -> Vector2i:
	var safe_area = get_safe_area()
	return safe_area.size if safe_area.size != Vector2i.ZERO else DisplayServer.window_get_size()