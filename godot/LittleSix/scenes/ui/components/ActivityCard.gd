extends PanelContainer

signal card_tapped(activity_type: int)

@export var activity_type: int = TrainingActivity.Type.SPRINT_INTERVALS:
	set(value):
		activity_type = value
		_update_display()

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_border()

@export var is_disabled: bool = false:
	set(value):
		is_disabled = value
		modulate = Color.GRAY if value else Color.WHITE

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_update_display()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not is_disabled:
		card_tapped.emit(activity_type)

func _update_display() -> void:
	var name = TrainingActivity.get_activity_name(activity_type)
	var effects = TrainingActivity.EFFECTS.get(activity_type, {})
	var effect_text = ""
	for stat in effects:
		if stat != "fatigue":
			var change = effects[stat]
			var sign = "+" if change > 0 else ""
			effect_text += sign + stat.capitalize() + " "
		if stat == "fatigue":
			var change = effects[stat]
			var sign = "+" if change > 0 else ""
			effect_text += sign + str(change) + " Fatigue"

	$VBoxContainer/NameLabel.text = name
	$VBoxContainer/EffectLabel.text = effect_text.strip_edges()

func _update_border() -> void:
	if is_selected:
		# Add crimson border
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.701961, 0.105882, 0.105882, 1)  # Crimson
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.701961, 0.105882, 0.105882, 1)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_right = 12
		style.corner_radius_bottom_left = 12
		add_theme_stylebox_override("panel", style)
	else:
		# Remove custom style to use default
		remove_theme_stylebox_override("panel")