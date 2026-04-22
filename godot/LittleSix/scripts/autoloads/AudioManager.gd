## AudioManager — Music crossfade and SFX pool management.
## Mobile autoplay unlock handled here.
extends Node

const MUSIC_CATALOG: Dictionary = {
	"logo":          "res://assets/audio/music/logo.ogg",
	"attract":       "res://assets/audio/music/attract.ogg",
	"hub":           "res://assets/audio/music/hub.ogg",
	"training":      "res://assets/audio/music/training.ogg",
	"lobby":         "res://assets/audio/music/lobby.ogg",
	"race_normal":   "res://assets/audio/music/race_normal.ogg",
	"race_intense":  "res://assets/audio/music/race_intense.ogg",
	"results_win":   "res://assets/audio/music/results_win.ogg",
	"results_loss":  "res://assets/audio/music/results_loss.ogg",
}

const SFX_CATALOG: Dictionary = {
	"bike_pedal_loop":   "res://assets/audio/sfx/bike_pedal.wav",
	"bike_sprint":       "res://assets/audio/sfx/bike_sprint.wav",
	"bike_brake":        "res://assets/audio/sfx/bike_brake.wav",
	"burn_skid":         "res://assets/audio/sfx/burn_skid.wav",
	"draft_whoosh":      "res://assets/audio/sfx/draft_whoosh.wav",
	"crash_impact":      "res://assets/audio/sfx/crash_impact.wav",
	"exchange_click":    "res://assets/audio/sfx/exchange_click.wav",
	"bell_lap":          "res://assets/audio/sfx/bell_lap.wav",
	"race_start_horn":   "res://assets/audio/sfx/race_start_horn.wav",
	"lap_whoosh":        "res://assets/audio/sfx/lap_whoosh.wav",
	"position_up":       "res://assets/audio/sfx/position_up.wav",
	"position_down":     "res://assets/audio/sfx/position_down.wav",
	"stat_increase":     "res://assets/audio/sfx/stat_up.wav",
	"stat_decrease":     "res://assets/audio/sfx/stat_down.wav",
	"fatigue_warning":   "res://assets/audio/sfx/fatigue_warn.wav",
	"injury_event":      "res://assets/audio/sfx/injury.wav",
	"event_positive":    "res://assets/audio/sfx/event_good.wav",
	"event_negative":    "res://assets/audio/sfx/event_bad.wav",
	"button_tap":        "res://assets/audio/sfx/tap.wav",
	"back_nav":          "res://assets/audio/sfx/back.wav",
	"screen_appear":     "res://assets/audio/sfx/appear.wav",
	"unlock":            "res://assets/audio/sfx/unlock.wav",
	"notification":      "res://assets/audio/sfx/notify.wav",
	"countdown_tick":    "res://assets/audio/sfx/tick.wav",
	"countdown_go":      "res://assets/audio/sfx/go.wav",
	"crowd_cheer":       "res://assets/audio/sfx/crowd_cheer.wav",
	"crowd_gasp":        "res://assets/audio/sfx/crowd_gasp.wav",
	"crowd_eruption":    "res://assets/audio/sfx/crowd_eruption.wav",
}

const SFX_POOL_SIZE := 8

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_layer: int = 0
var _current_track: String = ""
var _audio_unlocked: bool = false
var _sfx_pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	# Skip audio on headless server
	if DisplayServer.get_name() == "headless":
		return

	_music_a = AudioStreamPlayer.new()
	_music_a.bus = "Music"
	add_child(_music_a)

	_music_b = AudioStreamPlayer.new()
	_music_b.bus = "Music"
	_music_b.volume_db = -80.0
	add_child(_music_b)

	for i in SFX_POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	# Connect EventBus signals
	EventBus.music_track_requested.connect(func(id, fade): play_music(id, fade))
	EventBus.sfx_requested.connect(func(id, _pos): play_sfx(id))
	EventBus.game_state_changed.connect(_on_state_changed)
	EventBus.bell_lap_triggered.connect(_on_bell_lap)
	EventBus.fatigue_threshold_crossed.connect(_on_fatigue_threshold)
	EventBus.crash_occurred.connect(func(_id): play_sfx("crowd_gasp"))
	EventBus.exchange_executed.connect(func(_t, _o, _i, is_burn):
		play_sfx("exchange_click")
		if is_burn:
			play_sfx("burn_skid")
	)

	# Apply saved volume settings
	set_music_volume(SaveManager.get_setting("music_volume", 0.8))
	set_sfx_volume(SaveManager.get_setting("sfx_volume", 1.0))


func unlock_audio() -> void:
	if _audio_unlocked:
		return
	_audio_unlocked = true
	# The first music play will happen naturally via game_state_changed


func play_music(track_id: String, fade_time: float = 1.0) -> void:
	if track_id == _current_track:
		return
	if DisplayServer.get_name() == "headless":
		return

	var path = MUSIC_CATALOG.get(track_id, "")
	if path == "" or not ResourceLoader.exists(path):
		# Placeholder: no music file yet, just track what should be playing
		_current_track = track_id
		return

	_current_track = track_id
	var inactive: AudioStreamPlayer = _music_b if _active_layer == 0 else _music_a
	var active: AudioStreamPlayer = _music_a if _active_layer == 0 else _music_b

	inactive.stream = load(path)
	inactive.volume_db = -80.0
	inactive.play()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(inactive, "volume_db", 0.0, max(fade_time, 0.01))
	tween.tween_property(active, "volume_db", -80.0, max(fade_time, 0.01))
	tween.finished.connect(func():
		active.stop()
		_active_layer = 1 - _active_layer
	)


func stop_music(fade_time: float = 0.5) -> void:
	var active: AudioStreamPlayer = _music_a if _active_layer == 0 else _music_b
	var tween = create_tween()
	tween.tween_property(active, "volume_db", -80.0, max(fade_time, 0.01))
	tween.finished.connect(func():
		active.stop()
		_current_track = ""
	)


func play_sfx(sfx_id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var stream = _load_sfx(sfx_id)
	if stream == null:
		return

	for player in _sfx_pool:
		if not player.playing:
			player.bus = "SFX"
			player.stream = stream
			player.play()
			return

	# All busy — interrupt the first one
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()


func play_sfx_at(sfx_id: String, world_pos: Vector3) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var stream = _load_sfx(sfx_id)
	if stream == null:
		return

	var p3d = AudioStreamPlayer3D.new()
	p3d.bus = "SFX"
	p3d.stream = stream
	p3d.global_position = world_pos
	p3d.max_distance = 50.0
	get_tree().root.add_child(p3d)
	p3d.play()
	p3d.finished.connect(p3d.queue_free)


func set_music_volume(linear: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var db = linear_to_db(max(0.001, linear))
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, db)


func set_sfx_volume(linear: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var db = linear_to_db(max(0.001, linear))
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, db)


func _load_sfx(sfx_id: String) -> AudioStream:
	var path = SFX_CATALOG.get(sfx_id, "")
	if path == "":
		push_warning("AudioManager: unknown SFX id '" + sfx_id + "'")
		return null
	if not ResourceLoader.exists(path):
		# Placeholder: log but don't crash
		return null
	return load(path)


func _on_state_changed(new_state: int) -> void:
	match new_state:
		GameManager.GameState.LOGO:
			play_music("logo", 0.5)
		GameManager.GameState.CINEMATIC:
			play_music("attract", 2.0)
		GameManager.GameState.TITLE:
			pass  # Continue attract
		GameManager.GameState.DEMO:
			play_music("race_normal", 1.0)
		GameManager.GameState.MAIN_HUB:
			play_music("hub", 1.5)
		GameManager.GameState.TRAINING_DAY, GameManager.GameState.TRAINING_RESULTS:
			play_music("training", 1.0)
		GameManager.GameState.LOBBY:
			play_music("lobby", 1.0)
		GameManager.GameState.RACE_ACTIVE, GameManager.GameState.RACE_QUALIFYING, GameManager.GameState.SPRING_EVENT:
			play_music("race_normal", 1.0)
		GameManager.GameState.RACE_RESULTS:
			pass  # Results music triggered by race_finished signal


func _on_bell_lap() -> void:
	play_sfx("bell_lap")
	play_sfx("crowd_eruption")
	# Hard cut + brief silence + race_intense
	var active: AudioStreamPlayer = _music_a if _active_layer == 0 else _music_b
	active.stop()
	_current_track = ""
	get_tree().create_timer(0.1).timeout.connect(func(): play_music("race_intense", 0.0))


func _on_fatigue_threshold(old_level: String, new_level: String) -> void:
	if new_level in ["OVERLOADED", "DANGER ZONE"]:
		play_sfx("fatigue_warning")
