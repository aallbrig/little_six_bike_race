extends HBoxContainer

@export var stat_name: String = "STAT":
	set(value):
		stat_name = value
		$Label.text = value.to_upper()

@export var value: int = 0:
	set(new_value):
		if new_value != value:
			var old_value = value
			value = clamp(new_value, 0, 100)
			_animate_bar(old_value, value)
			$ValueLabel.text = str(value)
			_show_delta(value - old_value)

@export var bar_color: Color = Color.GREEN:
	set(value):
		bar_color = value
		if $ProgressBar:
			$ProgressBar.get_theme_stylebox("fill").bg_color = value

func _ready() -> void:
	$Label.text = stat_name.to_upper()
	$ProgressBar.value = value
	$ValueLabel.text = str(value)
	bar_color = bar_color  # Trigger setter

func _animate_bar(from_value: int, to_value: int) -> void:
	$ProgressBar.value = from_value
	var tween = create_tween()
	tween.tween_property($ProgressBar, "value", to_value, 0.4).set_ease(Tween.EASE_OUT)

func _show_delta(delta: int) -> void:
	if delta == 0:
		return

	var delta_label = Label.new()
	delta_label.text = ("+" if delta > 0 else "") + str(delta)
	delta_label.modulate = Color.GREEN if delta > 0 else Color.RED
	delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Position above the progress bar
	var pos = $ProgressBar.global_position
	pos.y -= 20
	pos.x += $ProgressBar.size.x / 2 - delta_label.size.x / 2
	delta_label.global_position = pos

	get_tree().root.add_child(delta_label)

	# Animate up and fade out
	var tween = create_tween()
	tween.tween_property(delta_label, "global_position:y", pos.y - 30, 1.0)
	tween.parallel().tween_property(delta_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): delta_label.queue_free())