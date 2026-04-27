# Manages visual effects for the race (particles, screen effects, etc.)
extends Node3D

@onready var sprint_trail: GPUParticles3D = $SprintTrail
@onready var speed_lines: GPUParticles3D = $SpeedLines
@onready var dust_trail: GPUParticles3D = $DustTrail

func _ready() -> void:
	# Connect to race events
	EventBus.sprint_button_pressed.connect(_on_sprint_pressed)
	EventBus.brake_button_pressed.connect(_on_brake_pressed)
	EventBus.race_started.connect(_on_race_started)
	EventBus.race_finished.connect(_on_race_finished)
	EventBus.crash_occurred.connect(_on_crash_occurred)

	# Initially disable all effects
	_set_all_effects_visible(false)

func _on_sprint_pressed(pressed: bool) -> void:
	if sprint_trail:
		sprint_trail.emitting = pressed
	if speed_lines:
		speed_lines.emitting = pressed

func _on_brake_pressed(pressed: bool) -> void:
	if dust_trail:
		dust_trail.emitting = pressed

func _on_race_started() -> void:
	# Brief celebration effect
	_play_start_effect()

func _on_race_finished(_results: Array) -> void:
	# Victory celebration
	_play_finish_effect()

func _on_crash_occurred(_racer_id: int) -> void:
	# Crash sparks/debris
	_play_crash_effect()

func _play_start_effect() -> void:
	# Could add confetti or light flash effect
	pass

func _play_finish_effect() -> void:
	# Victory particles
	if sprint_trail:
		sprint_trail.emitting = true
		# Auto-disable after celebration
		await get_tree().create_timer(3.0).wait
		sprint_trail.emitting = false

func _play_crash_effect() -> void:
	# Crash debris particles
	pass

func _set_all_effects_visible(visible: bool) -> void:
	for child in get_children():
		if child is GPUParticles3D:
			child.emitting = visible