extends CanvasLayer
class_name RotateOverlay

# Overlay that appears when race requires landscape but device is in portrait

var _target_orientation = DisplayServer.SCREEN_LANDSCAPE
var _check_timer: Timer

func _ready() -> void:
	# Create timer to check orientation periodically
	_check_timer = Timer.new()
	_check_timer.wait_time = 0.5
	_check_timer.timeout.connect(_check_orientation)
	add_child(_check_timer)
	_check_timer.start()

	# Initial orientation check
	_check_orientation()

func _check_orientation() -> void:
	var current_orientation = DisplayServer.screen_get_orientation()

	# Hide overlay if we're in the correct orientation
	if _target_orientation == DisplayServer.SCREEN_LANDSCAPE:
		if current_orientation == DisplayServer.SCREEN_LANDSCAPE:
			hide_overlay()
	elif _target_orientation == DisplayServer.SCREEN_PORTRAIT:
		if current_orientation == DisplayServer.SCREEN_PORTRAIT:
			hide_overlay()

func set_target_orientation(orientation: int) -> void:
	_target_orientation = orientation as DisplayServer.ScreenOrientation
	_check_orientation()  # Immediate check

func show_overlay() -> void:
	show()
	_check_timer.start()

func hide_overlay() -> void:
	hide()
	_check_timer.stop()

func _exit_tree() -> void:
	if _check_timer:
		_check_timer.stop()