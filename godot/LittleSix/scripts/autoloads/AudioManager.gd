extends Node

const SFX_CATALOG = {
	# Training & UI
	"activity_selected": "res://assets/audio/sfx/ui_click.ogg",
	"training_complete": "res://assets/audio/sfx/victory.ogg",
	"fatigue_warning": "res://assets/audio/sfx/fatigue_warning.ogg",
	"ui_click": "res://assets/audio/sfx/ui_click.ogg",
	"ui_hover": "res://assets/audio/sfx/ui_hover.ogg",

	# Race Actions
	"pedal_stroke": "res://assets/audio/sfx/ui_click.ogg",  # Placeholder - should be cycling sound
	"sprint_start": "res://assets/audio/sfx/sprint.ogg",
	"sprint_end": "res://assets/audio/sfx/sprint.ogg",
	"brake_applied": "res://assets/audio/sfx/ui_click.ogg",  # Placeholder
	"exchange_complete": "res://assets/audio/sfx/exchange.ogg",
	"burn_activated": "res://assets/audio/sfx/burn.ogg",

	# Race Events
	"bell_lap": "res://assets/audio/sfx/bell_lap.ogg",
	"lap_complete": "res://assets/audio/sfx/victory.ogg",
	"race_start": "res://assets/audio/sfx/bell_lap.ogg",
	"race_finish": "res://assets/audio/sfx/victory.ogg",
	"crowd_cheer": "res://assets/audio/sfx/victory.ogg",

	# Feedback
	"crash": "res://assets/audio/sfx/crash.ogg",
	"drafting_enter": "res://assets/audio/sfx/drafting.ogg",
	"drafting_exit": "res://assets/audio/sfx/drafting.ogg",
	"pit_zone_enter": "res://assets/audio/sfx/pit_zone.ogg",
}

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _positional_sfx_template: AudioStreamPlayer3D

var _music_volume: float = 0.8
var _sfx_volume: float = 1.0

func _ready() -> void:
	# Create audio players
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	_ui_player = AudioStreamPlayer.new()
	_positional_sfx_template = AudioStreamPlayer3D.new()

	add_child(_music_a)
	add_child(_music_b)
	add_child(_ui_player)
	add_child(_positional_sfx_template)

	# Load audio settings
	_load_audio_settings()

	# Connect to EventBus
	EventBus.music_track_requested.connect(play_music)
	EventBus.sfx_requested.connect(_on_sfx_requested)
	EventBus.game_state_changed.connect(_on_game_state_changed)

	# Race events
	EventBus.race_started.connect(_on_race_started)
	EventBus.lap_completed.connect(_on_lap_completed)
	EventBus.race_finished.connect(_on_race_finished)
	EventBus.sprint_button_pressed.connect(_on_sprint_button_pressed)
	EventBus.brake_button_pressed.connect(_on_brake_button_pressed)
	EventBus.exchange_button_tapped.connect(_on_exchange_button_tapped)
	EventBus.bell_lap_triggered.connect(_on_bell_lap_triggered)

	# Training events
	EventBus.training_activity_chosen.connect(_on_training_activity_chosen)
	EventBus.training_activity_resolved.connect(_on_training_activity_resolved)
	EventBus.fatigue_threshold_crossed.connect(_on_fatigue_threshold_crossed)

func play_music(track_id: String, fade_time: float = 1.0) -> void:
	var track_path = "res://assets/audio/music/" + track_id + ".ogg"
	var stream = load(track_path)
	if not stream:
		# Silent fallback for missing assets during development
		print("AudioManager: Missing music file: ", track_path)
		return

	# Crossfade between music layers A/B
	var active_player = _music_a if _music_a.playing else _music_b
	var inactive_player = _music_b if active_player == _music_a else _music_a

	inactive_player.stream = stream
	inactive_player.volume_db = linear_to_db(_music_volume)
	inactive_player.play()

	if active_player.playing:
		# Simple crossfade using tween
		var tween = create_tween()
		tween.tween_property(active_player, "volume_db", linear_to_db(0.0), fade_time)
		tween.tween_callback(active_player.stop)
		tween.tween_property(inactive_player, "volume_db", linear_to_db(_music_volume), fade_time)

func stop_music(_fade_time: float = 0.5) -> void:
	_music_a.stop()
	_music_b.stop()

func play_sfx(sfx_id: String, _bus: String = "SFX") -> void:
	var sfx_path = SFX_CATALOG.get(sfx_id)
	if not sfx_path:
		print("AudioManager: SFX not found in catalog: " + sfx_id)
		return

	var stream = load(sfx_path)
	if not stream:
		print("AudioManager: Could not load SFX: " + sfx_path)
		return

	_ui_player.stream = stream
	_ui_player.volume_db = linear_to_db(_sfx_volume)
	_ui_player.play()

func play_sfx_at(sfx_id: String, world_position: Vector3) -> void:
	var sfx_path = SFX_CATALOG.get(sfx_id)
	if not sfx_path:
		print("AudioManager: SFX not found in catalog: " + sfx_id)
		return

	var stream = load(sfx_path)
	if not stream:
		print("AudioManager: Could not load SFX: " + sfx_path)
		return

	var player = _positional_sfx_template.duplicate()
	player.stream = stream
	player.position = world_position
	player.volume_db = linear_to_db(_sfx_volume)
	add_child(player)
	player.play()

	# Auto-remove after playing
	player.finished.connect(func(): player.queue_free())

func _load_audio_settings() -> void:
	if SaveManager.settings_data:
		_music_volume = SaveManager.settings_data.music_volume
		_sfx_volume = SaveManager.settings_data.sfx_volume
	else:
		# Fallback to defaults
		_music_volume = 0.8
		_sfx_volume = 1.0

func set_music_volume(linear: float) -> void:
	_music_volume = clamp(linear, 0.0, 1.0)
	_music_a.volume_db = linear_to_db(_music_volume)
	_music_b.volume_db = linear_to_db(_music_volume)

	# Save to settings
	if SaveManager.settings_data:
		SaveManager.settings_data.music_volume = _music_volume
		SaveManager.save_game()

func set_sfx_volume(linear: float) -> void:
	_sfx_volume = clamp(linear, 0.0, 1.0)

	# Save to settings
	if SaveManager.settings_data:
		SaveManager.settings_data.sfx_volume = _sfx_volume
		SaveManager.save_game()

func unlock_audio() -> void:
	# Mobile browsers require user interaction before playing audio
	if OS.has_feature("web"):
		play_sfx("ui_click")  # Silent click to unlock audio

func _on_sfx_requested(sfx_id: String, position: Vector3) -> void:
	if position == Vector3.ZERO:
		play_sfx(sfx_id)
	else:
		play_sfx_at(sfx_id, position)

# Race event handlers
func _on_race_started() -> void:
	play_sfx("race_start")

func _on_lap_completed(_racer_id: int, lap_number: int, _lap_time: float) -> void:
	if lap_number == 49:  # Final lap
		play_sfx("bell_lap")
	else:
		play_sfx("lap_complete")

func _on_race_finished(results: Array) -> void:
	# Check if player won
	if results.size() > 0 and results[0].racer_id == 0:  # Assuming player is racer 0
		play_sfx("crowd_cheer")
	play_sfx("race_finish")

func _on_sprint_button_pressed(pressed: bool) -> void:
	if pressed:
		play_sfx("sprint_start")
	else:
		play_sfx("sprint_end")

func _on_brake_button_pressed(pressed: bool) -> void:
	if pressed:
		play_sfx("brake_applied")

func _on_exchange_button_tapped() -> void:
	play_sfx("exchange_complete")

func _on_bell_lap_triggered() -> void:
	play_sfx("bell_lap")

# Training event handlers
func _on_training_activity_chosen(_activity: TrainingActivity.Type, _slot: int) -> void:
	play_sfx("activity_selected")

func _on_training_activity_resolved(_activity: TrainingActivity.Type, _changes: Dictionary) -> void:
	play_sfx("training_complete")

func _on_fatigue_threshold_crossed(_old_level: String, new_level: String) -> void:
	if new_level == "TIRED" or new_level == "OVERLOADED":
		play_sfx("fatigue_warning")

func _on_game_state_changed(new_state: int) -> void:
	# Update music based on game state
	match new_state:
		GameManager.GameState.LOGO:
			play_music("logo_theme")
		GameManager.GameState.MAIN_HUB:
			play_music("hub_theme")
		GameManager.GameState.RACE_ACTIVE:
			play_music("race_theme")
		GameManager.GameState.TRAINING_DAY:
			play_music("training_theme")
		_:
			pass
