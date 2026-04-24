extends Control

@export var fatigue: int = 0:
	set(value):
		fatigue = clamp(value, 0, 100)
		queue_redraw()
		_update_label()

func _ready() -> void:
	_update_label()

func _draw() -> void:
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - 10
	var angle_from = -PI/2  # Start from top
	var angle_to = angle_from + (fatigue / 100.0) * 2 * PI

	# Choose color based on fatigue level
	var color = Color.GREEN
	if fatigue > 70:
		color = Color.RED
	elif fatigue > 30:
		color = Color.YELLOW

	# Draw the arc
	var points = []
	var colors = []
	points.append(center)
	colors.append(color)

	var num_segments = 32
	for i in range(num_segments + 1):
		var angle = angle_from + (i / float(num_segments)) * (angle_to - angle_from)
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
		colors.append(color)

	# Draw filled arc
	draw_polygon(points, colors)

func _update_label() -> void:
	if fatigue <= 30:
		$Label.text = "FRESH"
	elif fatigue <= 70:
		$Label.text = "TIRED"
	else:
		$Label.text = "OVERLOADED"