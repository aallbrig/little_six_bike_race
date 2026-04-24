extends HBoxContainer

@export var player_name: String = "Waiting...":
	set(value):
		player_name = value
		$NameLabel.text = value

@export var player_color: Color = Color.WHITE:
	set(value):
		player_color = value
		$ColorSwatchRect.color = value

@export var is_ready: bool = false:
	set(value):
		is_ready = value
		$ReadyBadge.visible = value