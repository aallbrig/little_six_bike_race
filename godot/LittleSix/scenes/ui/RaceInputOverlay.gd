extends Control

var _left_touch_id: int = -1
var _right_touch_id: int = -1
var _brake_touch_id: int = -1
var _sprint_touch_id: int = -1
var _exchange_visible: bool = false

func _ready() -> void:
	# Make invisible but capture input
	modulate.a = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_register_touch(event.index, event.position)
		else:
			_release_touch(event.index)

func _register_touch(id: int, pos: Vector2) -> void:
	var screen_width = get_viewport().size.x
	var screen_height = get_viewport().size.y

	# Sprint button: top-right quadrant
	if _is_in_sprint_zone(pos, screen_width, screen_height):
		_sprint_touch_id = id
		EventBus.sprint_button_pressed.emit(true)
	# Brake button: bottom-right
	elif _is_in_brake_zone(pos, screen_width, screen_height):
		_brake_touch_id = id
		EventBus.brake_button_pressed.emit(true)
	# Exchange: center-bottom (only if visible)
	elif _is_in_exchange_zone(pos, screen_width, screen_height) and _exchange_visible:
		EventBus.exchange_button_tapped.emit()
	# Left half: steer left
	elif pos.x < screen_width / 2:
		_left_touch_id = id
		EventBus.steer_input_changed.emit(-1.0)
	# Right half (not button zones): steer right
	else:
		_right_touch_id = id
		EventBus.steer_input_changed.emit(1.0)

func _release_touch(id: int) -> void:
	if id == _left_touch_id:
		_left_touch_id = -1
		EventBus.steer_input_changed.emit(0.0)
	elif id == _right_touch_id:
		_right_touch_id = -1
		EventBus.steer_input_changed.emit(0.0)
	elif id == _brake_touch_id:
		_brake_touch_id = -1
		EventBus.brake_button_pressed.emit(false)
	elif id == _sprint_touch_id:
		_sprint_touch_id = -1
		EventBus.sprint_button_pressed.emit(false)

func _is_in_sprint_zone(pos: Vector2, width: float, height: float) -> bool:
	return pos.x > width * 0.75 and pos.y < height * 0.25

func _is_in_brake_zone(pos: Vector2, width: float, height: float) -> bool:
	return pos.x > width * 0.75 and pos.y > height * 0.75

func _is_in_exchange_zone(pos: Vector2, width: float, height: float) -> bool:
	return pos.x > width * 0.4 and pos.x < width * 0.6 and pos.y > height * 0.8

func set_exchange_visible(show_exchange: bool) -> void:
	_exchange_visible = show_exchange