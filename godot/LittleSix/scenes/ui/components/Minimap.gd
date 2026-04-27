extends Control

var rider_dots = []

func _ready() -> void:
	# Create dots for 6 riders
	for i in range(6):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = _get_rider_color(i)
		$MinimapOverlay/RiderDots.add_child(dot)
		rider_dots.append(dot)

func update_rider_positions(positions: Array) -> void:
	for i in range(min(positions.size(), rider_dots.size())):
		var pos = positions[i]
		# Convert world position to minimap UV coordinates (0-1)
		var uv_x = (pos.x + 50) / 100.0	 # Assuming track bounds -50 to 50
		var uv_y = (pos.z + 80) / 160.0	 # Assuming track bounds -80 to 80

		rider_dots[i].position = Vector2(uv_x * size.x, uv_y * size.y)
		rider_dots[i].visible = true

func _get_rider_color(index: int) -> Color:
	var colors = [
		Color.RED,
		Color.BLUE,
		Color.GREEN,
		Color.YELLOW,
		Color.MAGENTA,
		Color.CYAN
	]
	return colors[index % colors.size()]