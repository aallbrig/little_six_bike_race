extends Node

## Event Telemetry Logger
# Listens to ALL EventBus signals and produces console logs for observability.
# Configurable via SettingsData.telemetry_enabled and telemetry_level.

const LOG_PREFIX = "[TELEMETRY]"
var _enabled: bool = true
var _log_level: int = 2  # 0=None, 1=Error, 2=Info, 3=Debug
var _signal_count: int = 0
var _start_time: int = 0

func _ready() -> void:
	_start_time = Time.get_ticks_msec()
	_connect_to_all_signals()
	print_rich("[color=cyan]%s Initialized - monitoring all EventBus signals[/color]" % LOG_PREFIX)

func _connect_to_all_signals() -> void:
	# Game State
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.scene_transition_requested.connect(_on_scene_transition_requested)

	# Player/Account
	EventBus.player_logged_in.connect(_on_player_logged_in)
	EventBus.player_logged_out.connect(_on_player_logged_out)
	EventBus.racer_created.connect(_on_racer_created)
	EventBus.racer_stat_changed.connect(_on_racer_stat_changed)

	# Training
	EventBus.training_day_started.connect(_on_training_day_started)
	EventBus.training_activity_chosen.connect(_on_training_activity_chosen)
	EventBus.training_activity_resolved.connect(_on_training_activity_resolved)
	EventBus.training_random_event_fired.connect(_on_training_random_event_fired)
	EventBus.training_day_completed.connect(_on_training_day_completed)
	EventBus.fatigue_threshold_crossed.connect(_on_fatigue_threshold_crossed)
	EventBus.injury_occurred.connect(_on_injury_occurred)

	# Race
	EventBus.race_started.connect(_on_race_started)
	EventBus.lap_completed.connect(_on_lap_completed)
	EventBus.racer_position_changed.connect(_on_racer_position_changed)
	EventBus.race_finished.connect(_on_race_finished)

	# Input
	EventBus.steer_input_changed.connect(_on_steer_input_changed)
	EventBus.sprint_button_pressed.connect(_on_sprint_button_pressed)
	EventBus.brake_button_pressed.connect(_on_brake_button_pressed)
	EventBus.exchange_button_tapped.connect(_on_exchange_button_tapped)

	# Audio/UI
	EventBus.music_track_requested.connect(_on_music_track_requested)
	EventBus.sfx_requested.connect(_on_sfx_requested)

	# Host Bridge
	EventBus.host_event_sent.connect(_on_host_event_sent)
	EventBus.host_event_received.connect(_on_host_event_received)

# Signal Handlers with consistent formatting
func _log_event(signal_name: String, params: Array = []) -> void:
	if not _enabled: return
	_signal_count += 1

	var time = (Time.get_ticks_msec() - _start_time) / 1000.0
	var param_str = ""
	if not params.is_empty():
	    var param_parts = []
	    for p in params:
	        if p is Dictionary:
	            param_parts.append(str(p))
	        elif p is Object and p.has_method("to_dict"):
	            param_parts.append(str(p.to_dict()))
	        else:
	            param_parts.append(str(p))
	    param_str = "(" + ", ".join(param_parts) + ")"

	print_rich("[color=cyan]%s[/color] [color=yellow]%.2fs[/color] %s%s" % [LOG_PREFIX, time, signal_name, param_str])

# Individual handlers (kept minimal to avoid performance impact)
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	_log_event("game_state_changed", [new_state])
func _on_scene_transition_requested(target_scene: String, data: Dictionary) -> void:
	_log_event("scene_transition_requested", [target_scene, data])
func _on_player_logged_in(player_data: PlayerData) -> void:
	_log_event("player_logged_in", [player_data.display_name if player_data else "null"])
func _on_player_logged_out() -> void:
	_log_event("player_logged_out")
func _on_racer_created(racer: RacerData) -> void:
	_log_event("racer_created", [racer.name if racer else "null"])
func _on_racer_stat_changed(stat: String, old_value: int, new_value: int) -> void:
	_log_event("racer_stat_changed", [stat, old_value, new_value])

func _on_training_day_started(week: int, day: int) -> void:
	_log_event("training_day_started", [week, day])
func _on_training_activity_chosen(activity: TrainingActivity.Type, slot: int) -> void:
	_log_event("training_activity_chosen", [activity, slot])
func _on_training_activity_resolved(activity: TrainingActivity.Type, changes: Dictionary) -> void:
	_log_event("training_activity_resolved", [activity, changes])
func _on_training_random_event_fired(event_id: String, effects: Dictionary) -> void:
	_log_event("training_random_event_fired", [event_id, effects])
func _on_training_day_completed(week: int, day: int, summary: Dictionary) -> void:
	_log_event("training_day_completed", [week, day, summary])
func _on_fatigue_threshold_crossed(old_level: String, new_level: String) -> void:
	_log_event("fatigue_threshold_crossed", [old_level, new_level])
func _on_injury_occurred(stat_affected: String, duration_days: int) -> void:
	_log_event("injury_occurred", [stat_affected, duration_days])

func _on_race_started() -> void:
	_log_event("race_started")
func _on_lap_completed(racer_id: int, lap_number: int, lap_time: float) -> void:
	_log_event("lap_completed", [racer_id, lap_number, lap_time])
func _on_racer_position_changed(racer_id: int, new_position: int) -> void:
	_log_event("racer_position_changed", [racer_id, new_position])
func _on_race_finished(results: Array) -> void:
	_log_event("race_finished", [results.size()])

func _on_steer_input_changed(value: float) -> void:
	# Less verbose for high-frequency input
	if _log_level >= 3:
	    _log_event("steer_input_changed", [value])
func _on_sprint_button_pressed(pressed: bool) -> void:
	_log_event("sprint_button_pressed", [pressed])
func _on_brake_button_pressed(pressed: bool) -> void:
	_log_event("brake_button_pressed", [pressed])
func _on_exchange_button_tapped() -> void:
	_log_event("exchange_button_tapped")

func _on_music_track_requested(track_id: String, fade_time: float) -> void:
	_log_event("music_track_requested", [track_id, fade_time])
func _on_sfx_requested(sfx_id: String, position: Vector3) -> void:
	_log_event("sfx_requested", [sfx_id, position])

func _on_host_event_sent(type: String, payload: Dictionary) -> void:
	_log_event("host_event_sent", [type, payload])
func _on_host_event_received(type: String, payload: Dictionary) -> void:
	_log_event("host_event_received", [type, payload])

# Public API
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	print_rich("[color=cyan]%s[/color] Telemetry %s" % [LOG_PREFIX, "ENABLED" if enabled else "DISABLED"])

func set_log_level(level: int) -> void:
	_log_level = clamp(level, 0, 3)
	var level_names = ["NONE", "ERROR", "INFO", "DEBUG"]
	print_rich("[color=cyan]%s[/color] Log level set to: %s" % [LOG_PREFIX, level_names[_log_level]])

func get_stats() -> Dictionary:
	var uptime = (Time.get_ticks_msec() - _start_time) / 1000.0
	return {
	    "signals_logged": _signal_count,
	    "uptime_seconds": uptime,
	    "signals_per_second": _signal_count / max(1.0, uptime)
	}
