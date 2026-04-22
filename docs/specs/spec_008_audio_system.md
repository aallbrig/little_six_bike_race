# Spec 008 — Audio System

**Depends on:** Spec 001  
**Last Updated:** 2026-04-10  

---

## Overview

Implement the full audio system: AudioManager autoload, audio bus configuration, music crossfade, positional SFX, bike audio (pitch-scaled with speed), dynamic race music intensity, and mobile autoplay unlock. This spec covers implementation of the AudioManager from Spec 001 and all audio integration points.

---

## Requirements

### REQ-008-001: Audio Bus Layout
Create `audio_bus_layout.tres` in the project root:

```
Bus 0: Master       (no effects)
Bus 1: Music        (parent: Master)    [ReverbReverb for outdoor feel: room_size=0.3]
Bus 2: SFX          (parent: Master)    [no effects]
Bus 3: Crowd        (parent: Master)    [Reverb: room_size=0.8, simulates stadium]
Bus 4: UI           (parent: Master)    [no effects]
```

Volume defaults:
- Master: 0 dB
- Music: -3 dB
- SFX: 0 dB
- Crowd: -6 dB (crowds are loud but shouldn't overpower)
- UI: 0 dB

### REQ-008-002: SFX Catalog
`AudioManager` must contain a `SFX_CATALOG` constant dictionary mapping IDs to resource paths:

```gdscript
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
```

**Placeholder audio:** Until real audio assets exist, AudioManager must NOT crash when a file is missing. Use a fallback:
```gdscript
func _load_sfx(sfx_id: String) -> AudioStream:
    var path = SFX_CATALOG.get(sfx_id, "")
    if path == "" or not ResourceLoader.exists(path):
        push_warning("AudioManager: missing SFX '" + sfx_id + "'")
        return null
    return load(path)
```

### REQ-008-003: AudioManager Full Implementation

```gdscript
# scripts/autoloads/AudioManager.gd
class_name AudioManager
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

const SFX_CATALOG: Dictionary = { ... }  # as above

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
```

### REQ-008-004: Bike Pedal Audio (In Race)
In `RiderController.gd`, maintain a looping pedal audio player:

```gdscript
var _pedal_player: AudioStreamPlayer3D = null

func _setup_audio() -> void:
    _pedal_player = AudioStreamPlayer3D.new()
    _pedal_player.bus = "SFX"
    _pedal_player.stream = load("res://assets/audio/sfx/bike_pedal.wav")
    _pedal_player.autoplay = false
    add_child(_pedal_player)

func _update_pedal_audio(current_speed: float, max_speed: float) -> void:
    if current_speed < 0.5:
        if _pedal_player.playing:
            _pedal_player.stop()
        return
    
    if not _pedal_player.playing:
        _pedal_player.play()
    
    var speed_ratio = current_speed / max_speed
    _pedal_player.pitch_scale = lerp(0.6, 1.5, speed_ratio)
    _pedal_player.volume_db = lerp(-15.0, 0.0, speed_ratio)
```

### REQ-008-005: Dynamic Crowd Audio
In `RaceController.gd` or a `CrowdController` child node:

```gdscript
# Crowd cheering intensifies based on race state
var _crowd_player: AudioStreamPlayer
var _crowd_target_volume: float = -6.0

func _ready() -> void:
    _crowd_player = AudioStreamPlayer.new()
    _crowd_player.bus = "Crowd"
    _crowd_player.stream = load("res://assets/audio/sfx/crowd_idle.wav")
    add_child(_crowd_player)
    _crowd_player.play()
    
    EventBus.bell_lap_triggered.connect(_on_bell_lap)
    EventBus.racer_position_changed.connect(_on_position_change)
    EventBus.race_finished.connect(_on_race_finish)

func _process(delta: float) -> void:
    # Smoothly move crowd volume toward target
    _crowd_player.volume_db = move_toward(
        _crowd_player.volume_db, _crowd_target_volume, 3.0 * delta)

func _on_bell_lap() -> void:
    _crowd_target_volume = 6.0  # Crowd LOUD on bell lap

func _on_position_change(racer_id: int, new_pos: int) -> void:
    if racer_id == NetworkManager.local_player_id:
        if new_pos == 1:
            AudioManager.play_sfx("crowd_cheer")
            _crowd_target_volume = 0.0
        elif new_pos > 3:
            _crowd_target_volume = -9.0

func _on_race_finish(_results) -> void:
    AudioManager.play_sfx("crowd_eruption")
    _crowd_target_volume = -3.0
```

---

## Acceptance Criteria

- [ ] Audio bus layout loads without errors
- [ ] Music plays in Logo scene
- [ ] Music crossfades between scenes (no hard cut except bell lap)
- [ ] play_sfx() with missing SFX ID logs a warning but does not crash
- [ ] Bike pedal pitch scales from 0.6 to 1.5 between stop and max speed
- [ ] Bell lap: hard cut, brief silence, race_intense resumes
- [ ] Crowd volume increases on bell lap
- [ ] Mobile autoplay unlock: audio works after first user tap
- [ ] Settings music/SFX sliders affect AudioServer bus volumes in real-time
- [ ] SFX pool: 8 simultaneous SFX without errors (test with crash + burn + crowd simultaneously)
- [ ] Positional SFX plays at world position and fades with distance
