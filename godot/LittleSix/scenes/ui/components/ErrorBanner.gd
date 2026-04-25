extends HBoxContainer

signal retry_pressed

@export var message: String = "":
	set(value):
	    message = value
	    $MessageLabel.text = value

@export var show_retry: bool = false:
	set(value):
	    show_retry = value
	    $RetryButton.visible = value

func _ready() -> void:
	visible = false
	$RetryButton.pressed.connect(_on_retry_pressed)

func show_error(error_message: String, can_retry: bool = false) -> void:
	message = error_message
	show_retry = can_retry
	visible = true

	# Auto-hide after 5 seconds if no retry
	if not can_retry:
	    var timer = get_tree().create_timer(5.0)
	    timer.timeout.connect(func(): visible = false)

func hide_error() -> void:
	visible = false

func _on_retry_pressed() -> void:
	retry_pressed.emit()
	hide_error()