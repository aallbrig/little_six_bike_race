extends CanvasLayer

func _ready() -> void:
	visible = false
	_check_orientation()

func _process(_delta: float) -> void:
	_check_orientation()

func _check_orientation() -> void:
	var screen_size = DisplayServer.window_get_size()
	var is_portrait = screen_size.y > screen_size.x

	# Show overlay if in portrait mode during race
	var should_show = is_portrait and GameManager.current_state == GameManager.GameState.RACE_ACTIVE

	if visible != should_show:
		visible = should_show
		if should_show:
			_try_lock_orientation()

func _try_lock_orientation() -> void:
	# Try to lock to landscape for race
	if DisplayServer.has_feature(DisplayServer.FEATURE_SCREEN_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)