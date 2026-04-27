extends PanelContainer

signal confirmed
signal cancelled

@export var title: String = "Confirm Action":
	set(value):
		title = value
		$VBoxContainer/TitleLabel.text = value

@export var message: String = "Are you sure?":
	set(value):
		message = value
		$VBoxContainer/MessageLabel.text = value

@export var confirm_text: String = "Confirm":
	set(value):
		confirm_text = value
		$VBoxContainer/ButtonContainer/ConfirmButton.text = value

@export var cancel_text: String = "Cancel":
	set(value):
		cancel_text = value
		$VBoxContainer/ButtonContainer/CancelButton.text = value

@export var is_destructive: bool = false:
	set(value):
		is_destructive = value
		if value:
			$VBoxContainer/ButtonContainer/ConfirmButton.theme_type_variation = "DangerButton"
		else:
			$VBoxContainer/ButtonContainer/ConfirmButton.theme_type_variation = "PrimaryButton"

func _ready() -> void:
	visible = false
	$VBoxContainer/ButtonContainer/CancelButton.pressed.connect(_on_cancel_pressed)
	$VBoxContainer/ButtonContainer/ConfirmButton.pressed.connect(_on_confirm_pressed)

func show_dialog() -> void:
	visible = true

func hide_dialog() -> void:
	visible = false

func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide_dialog()

func _on_confirm_pressed() -> void:
	confirmed.emit()
	hide_dialog()