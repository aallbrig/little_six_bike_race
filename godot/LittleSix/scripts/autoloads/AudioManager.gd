extends Node

const SFX_CATALOG = {
    "sprint": "res://assets/audio/sfx/sprint.wav",
    "crash": "res://assets/audio/sfx/crash.wav", 
    "exchange": "res://assets/audio/sfx/exchange.wav",
    "bell_lap": "res://assets/audio/sfx/bell_lap.wav",
    "victory": "res://assets/audio/sfx/victory.wav",
    "defeat": "res://assets/audio/sfx/defeat.wav",
    "ui_click": "res://assets/audio/sfx/ui_click.wav",
    "ui_hover": "res://assets/audio/sfx/ui_hover.wav",
    "fatigue_warning": "res://assets/audio/sfx/fatigue_warning.wav",
    "burn": "res://assets/audio/sfx/burn.wav",
    "drafting": "res://assets/audio/sfx/drafting.wav",
    "pit_zone": "res://assets/audio/sfx/pit_zone.wav",
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

    # Connect to EventBus
    EventBus.music_track_requested.connect(play_music)
    EventBus.sfx_requested.connect(_on_sfx_requested)
    EventBus.game_state_changed.connect(_on_game_state_changed)

func play_music(track_id: String, fade_time: float = 1.0) -> void:
    var track_path = "res://assets/audio/music/" + track_id + ".ogg"
    var stream = load(track_path)
    if not stream:
        # Silent fallback for missing assets during development
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

func stop_music(fade_time: float = 0.5) -> void:
    _music_a.stop()
    _music_b.stop()

func play_sfx(sfx_id: String) -> void:
    var sfx_path = SFX_CATALOG.get(sfx_id)
    if not sfx_path:
        push_error("SFX not found in catalog: " + sfx_id)
        return

    var stream = load(sfx_path)
    if stream:
        _ui_player.stream = stream
        _ui_player.volume_db = linear_to_db(_sfx_volume)
        _ui_player.play()

func play_sfx_at(sfx_id: String, world_position: Vector3) -> void:
    var sfx_path = SFX_CATALOG.get(sfx_id)
    if not sfx_path:
        push_error("SFX not found in catalog: " + sfx_id)
        return

    var stream = load(sfx_path)
    if stream:
        var player = _positional_sfx_template.duplicate()
        player.stream = stream
        player.position = world_position
        player.volume_db = linear_to_db(_sfx_volume)
        add_child(player)
        player.play()

        # Auto-remove after playing
        player.finished.connect(func(): player.queue_free())

func set_music_volume(linear: float) -> void:
    _music_volume = clamp(linear, 0.0, 1.0)
    _music_a.volume_db = linear_to_db(_music_volume)
    _music_b.volume_db = linear_to_db(_music_volume)

func set_sfx_volume(linear: float) -> void:
    _sfx_volume = clamp(linear, 0.0, 1.0)

func unlock_audio() -> void:
    # Mobile browsers require user interaction before playing audio
    if OS.has_feature("web"):
        play_sfx("ui_click")  # Silent click to unlock audio

func _on_sfx_requested(sfx_id: String, position: Vector3) -> void:
    if position == Vector3.ZERO:
        play_sfx(sfx_id)
    else:
        play_sfx_at(sfx_id, position)

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