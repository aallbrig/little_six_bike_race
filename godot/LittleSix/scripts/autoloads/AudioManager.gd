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
    # Bike & Racing
    "bike_pedal_loop":   "res://assets/audio/sfx/bike_pedal.wav",
    "bike_sprint":       "res://assets/audio/sfx/bike_sprint.wav",
    "bike_brake":        "res://assets/audio/sfx/bike_brake.wav",
    "burn_skid":         "res://assets/audio/sfx/burn_skid.wav",
    "draft_whoosh":      "res://assets/audio/sfx/draft_whoosh.wav",
    "crash_impact":      "res://assets/audio/sfx/crash_impact.wav",
    "exchange_click":    "res://assets/audio/sfx/exchange_click.wav",
    "bell_lap":          "res://assets/audio/sfx/bell_lap.wav",

    # Race Events
    "race_start_horn":   "res://assets/audio/sfx/race_start_horn.wav",
    "lap_whoosh":        "res://assets/audio/sfx/lap_whoosh.wav",
    "position_up":       "res://assets/audio/sfx/position_up.wav",
    "position_down":     "res://assets/audio/sfx/position_down.wav",

    # Training
    "stat_increase":     "res://assets/audio/sfx/stat_up.wav",
    "stat_decrease":     "res://assets/audio/sfx/stat_down.wav",
    "fatigue_warning":   "res://assets/audio/sfx/fatigue_warn.wav",
    "injury_event":      "res://assets/audio/sfx/injury.wav",
    "event_positive":    "res://assets/audio/sfx/event_good.wav",
    "event_negative":    "res://assets/audio/sfx/event_bad.wav",

    # UI
    "button_tap":        "res://assets/audio/sfx/tap.wav",
    "back_nav":          "res://assets/audio/sfx/back.wav",
    "screen_appear":     "res://assets/audio/sfx/appear.wav",
    "unlock":            "res://assets/audio/sfx/unlock.wav",
    "notification":      "res://assets/audio/sfx/notify.wav",
    "countdown_tick":    "res://assets/audio/sfx/tick.wav",
    "countdown_go":      "res://assets/audio/sfx/go.wav",

    # Crowd
    "crowd_idle_loop":   "res://assets/audio/sfx/crowd_idle.wav",
    "crowd_cheer":       "res://assets/audio/sfx/crowd_cheer.wav",
    "crowd_gasp":        "res://assets/audio/sfx/crowd_gasp.wav",
    "crowd_eruption":    "res://assets/audio/sfx/crowd_eruption.wav",
    "wind_ambient_loop": "res://assets/audio/sfx/wind.wav",
}

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_layer: int = 0  # 0 = A, 1 = B
var _current_track: String = ""
var _audio_unlocked: bool = false
var _sfx_pool: Array[AudioStreamPlayer] = []

const SFX_POOL_SIZE := 8

func _ready() -> void:
    _music_a = AudioStreamPlayer.new()
    _music_a.bus = "Music"
    add_child(_music_a)

    _music_b = AudioStreamPlayer.new()
    _music_b.bus = "Music"
    _music_b.volume_db = -80.0
    add_child(_music_b)

    # Pre-allocate SFX pool
    for i in SFX_POOL_SIZE:
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        _sfx_pool.append(player)

    # Connect to EventBus
    EventBus.music_track_requested.connect(_on_music_requested)
    EventBus.sfx_requested.connect(_on_sfx_requested)
    EventBus.game_state_changed.connect(_on_state_changed)
    EventBus.bell_lap_triggered.connect(_on_bell_lap)
    EventBus.fatigue_threshold_crossed.connect(_on_fatigue_threshold)
    EventBus.crash_occurred.connect(func(_id): play_sfx("crowd_gasp"))
    EventBus.exchange_executed.connect(func(_t, _o, _i, is_burn):
        play_sfx("exchange_click")
        if is_burn: play_sfx("burn_skid")
    )
    EventBus.training_activity_resolved.connect(func(_act, changes):
        for key in changes:
            if key != "fatigue":
                if changes[key] > 0: play_sfx("stat_increase")
                elif changes[key] < 0: play_sfx("stat_decrease")
    )

func play_music(track_id: String, fade_time: float = 1.0) -> void:
    if track_id == _current_track: return
    if not _audio_unlocked: return

    var path = MUSIC_CATALOG.get(track_id, "")
    if path == "" or not ResourceLoader.exists(path):
        push_warning("AudioManager: missing music track '" + track_id + "'")
        return

    _current_track = track_id
    var inactive = _music_b if _active_layer == 0 else _music_a
    var active = _music_a if _active_layer == 0 else _music_b

    inactive.stream = load(path)
    inactive.volume_db = -80.0
    inactive.play()

    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(inactive, "volume_db", 0.0, fade_time)
    tween.tween_property(active, "volume_db", -80.0, fade_time)
    await tween.finished

    active.stop()
    _active_layer = 1 - _active_layer

func stop_music(fade_time: float = 0.5) -> void:
    var active = _music_a if _active_layer == 0 else _music_b
    var tween = create_tween()
    tween.tween_property(active, "volume_db", -80.0, fade_time)
    await tween.finished
    active.stop()
    _current_track = ""

func play_sfx(sfx_id: String) -> void:
    if not _audio_unlocked: return
    var stream = _load_sfx(sfx_id)
    if stream == null: return

    # Find available pool player
    for player in _sfx_pool:
        if not player.playing:
            player.bus = "SFX"
            player.stream = stream
            player.play()
            return

    # All pooled players busy — use oldest (interrupt it)
    _sfx_pool[0].stream = stream
    _sfx_pool[0].play()

func play_sfx_at(sfx_id: String, world_pos: Vector3) -> void:
    if not _audio_unlocked: return
    var stream = _load_sfx(sfx_id)
    if stream == null: return

    var positional = AudioStreamPlayer3D.new()
    positional.bus = "SFX"
    positional.stream = stream
    positional.global_position = world_pos
    positional.max_distance = 50.0
    positional.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
    get_tree().root.add_child(positional)
    positional.play()
    await positional.finished
    positional.queue_free()



func set_music_volume(linear: float) -> void:
    var db = linear_to_db(max(0.001, linear))
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func set_sfx_volume(linear: float) -> void:
    var db = linear_to_db(max(0.001, linear))
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)

func unlock_audio() -> void:
    if _audio_unlocked: return
    # Play a silent buffer to unlock audio context on mobile
    var silent = AudioStreamPlayer.new()
    silent.bus = "UI"
    add_child(silent)
    silent.play()
    await get_tree().process_frame
    silent.queue_free()
    _audio_unlocked = true

func _load_sfx(sfx_id: String) -> AudioStream:
    var path = SFX_CATALOG.get(sfx_id, "")
    if path == "" or not ResourceLoader.exists(path):
        push_warning("AudioManager: missing SFX '" + sfx_id + "'")
        return null
    return load(path)

func _on_music_requested(track_id: String, fade_time: float = 1.0) -> void:
    play_music(track_id, fade_time)

func _on_sfx_requested(sfx_id: String, position: Vector3) -> void:
    if position == Vector3.ZERO:
        play_sfx(sfx_id)
    else:
        play_sfx_at(sfx_id, position)



func _on_state_changed(new_state: GameManager.GameState) -> void:
    match new_state:
        GameManager.GameState.LOGO:         play_music("logo", 0.5)
        GameManager.GameState.CINEMATIC:    play_music("attract", 2.0)
        GameManager.GameState.TITLE:        pass  # Attract continues
        GameManager.GameState.DEMO:         play_music("race_normal", 1.0)
        GameManager.GameState.MAIN_HUB:     play_music("hub", 1.5)
        GameManager.GameState.TRAINING_DAY: play_music("training", 1.0)
        GameManager.GameState.LOBBY:        play_music("lobby", 1.0)
        GameManager.GameState.RACE_ACTIVE:  play_music("race_normal", 1.0)

func _on_bell_lap() -> void:
    play_sfx("bell_lap")
    play_sfx("crowd_eruption")
    # Hard cut, brief silence, then race_intense
    var active = _music_a if _active_layer == 0 else _music_b
    active.stop()
    await get_tree().create_timer(0.1).timeout
    play_music("race_intense", 0.0)  # No crossfade — instant

func _on_fatigue_threshold(old_level: String, new_level: String) -> void:
    if new_level == "OVERLOADED" or new_level == "DANGER ZONE":
        play_sfx("fatigue_warning")
