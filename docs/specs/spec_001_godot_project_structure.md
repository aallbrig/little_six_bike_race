# Spec 001 — Godot Project Structure

**Depends on:** None  
**Blocking:** All other specs  
**Last Updated:** 2026-04-10  

---

## Overview

Establish the full Godot 4.6 project scaffold: `project.godot`, autoload registrations, export presets, directory layout, and all five autoload singletons with their full GDScript interfaces. All subsequent specs depend on this structure being in place.

---

## Requirements

### REQ-001-001: Project File
The `godot/LittleSix/project.godot` file must define:
- Application name: `LittleSix`
- Main scene: `res://scenes/logo/Logo.tscn`
- Display: viewport 1080×1920 (portrait base), stretch mode `canvas_items`, aspect `expand`
- Renderer: `mobile` (not `forward_plus`)
- ASTC/ETC2 texture compression enabled
- All 5 autoloads registered in dependency order

### REQ-001-002: Autoload Order
Autoloads registered in this exact order (dependency order):
1. `EventBus` → `res://scripts/autoloads/EventBus.gd`
2. `SaveManager` → `res://scripts/autoloads/SaveManager.gd`
3. `AudioManager` → `res://scripts/autoloads/AudioManager.gd`
4. `NetworkManager` → `res://scripts/autoloads/NetworkManager.gd`
5. `GameManager` → `res://scripts/autoloads/GameManager.gd`

### REQ-001-003: Export Presets
`export_presets.cfg` must define two presets:
- **Web**: HTML5/WASM export, SharedArrayBuffer enabled (requires COOP/COEP headers), compressed output
- **Linux Server**: Linux x86_64 export, headless mode enabled, no audio/rendering exports

### REQ-001-004: EventBus — Full Signal Catalog
`EventBus.gd` must declare exactly the signals listed in the TDD Section 3.1. No logic; signals only. All signal parameters must use typed parameters (Godot 4 typed signals).

### REQ-001-005: GameManager — State Machine
`GameManager.gd` must implement:
- `GameState` enum with all states from TDD Section 7
- `current_state: GameState` property
- `current_player: PlayerData` property (null until player created)
- `transition_to(state: GameState, data: Dictionary = {}) -> void` method
- State must emit `EventBus.game_state_changed` on every transition
- `_enter_state` and `_exit_state` internal handlers for each state

### REQ-001-006: NetworkManager — Connection Interface
`NetworkManager.gd` must implement:
- `ConnectionState` enum: `DISCONNECTED, CONNECTING, CONNECTED, IN_ROOM, IN_RACE`
- `state: ConnectionState` property
- `connect_to_server(url: String, token: String) -> void`
- `send_message(msg_type: String, payload: Dictionary) -> void`
- `disconnect_gracefully() -> void`
- On incoming message: parse JSON, emit `EventBus.network_message_received`
- Heartbeat: send `HEARTBEAT` every 1 second when `IN_ROOM` or `IN_RACE`
- Ping calculation: update `ping_ms` from `HEARTBEAT_ACK`; emit `EventBus.latency_updated`

### REQ-001-007: AudioManager — Playback Interface
`AudioManager.gd` must implement:
- Three `AudioStreamPlayer` nodes: `_music_a`, `_music_b`, `_ui_player`
- One `AudioStreamPlayer3D` template for positional SFX (instantiated on demand)
- `play_music(track_id: String, fade_time: float = 1.0) -> void` — crossfade between layers
- `stop_music(fade_time: float = 0.5) -> void`
- `play_sfx(sfx_id: String) -> void` — plays from `SFX_CATALOG` const
- `play_sfx_at(sfx_id: String, world_position: Vector3) -> void` — positional
- `set_music_volume(linear: float) -> void` — 0.0 to 1.0
- `set_sfx_volume(linear: float) -> void`
- `unlock_audio() -> void` — must be called on first user tap (mobile autoplay fix)
- Listens to `EventBus.music_track_requested` and `EventBus.sfx_requested`
- `SFX_CATALOG: Dictionary` maps sfx_id strings to `res://` paths

### REQ-001-008: SaveManager — Load/Save Interface
`SaveManager.gd` must implement:
- `SAVE_PATH: String = "user://save.json"`
- `player_data: PlayerData` — null if no save
- `settings_data: SettingsData` — always initialized with defaults
- `load_game() -> bool` — returns true if save found and loaded
- `save_game() -> void` — writes JSON to `SAVE_PATH`
- `wipe_save() -> void`
- `get_setting(key: String, default: Variant = null) -> Variant`
- `set_setting(key: String, value: Variant) -> void` — auto-saves settings
- Auto-save triggers after: training day complete, race results, settings change

### REQ-001-009: Data Resource Classes
The following GDScript `Resource` subclasses must exist as separate files:
- `scripts/training/RacerData.gd` — see TDD Section 6.1
- `scripts/training/PlayerData.gd` — see TDD Section 6.2
- `scripts/training/SeasonData.gd` — see TDD Section 6.3
- `scripts/training/TrainingActivity.gd` — see TDD Section 6.4 (use `class_name`, no extends Resource — it's a namespace/static class)
- `scripts/race/RaceResult.gd` — see TDD Section 6.5

### REQ-001-010: Directory Structure
All directories listed in TDD Section 2.1 must exist. Empty directories must contain a `.gitkeep` file.

### REQ-001-011: .gitignore
`godot/LittleSix/.gitignore` must exclude:
```
.godot/
*.import
export_presets.cfg.bak
```
Do NOT exclude `export_presets.cfg` itself (needed for CI/CD).

---

## Data Structures

### SettingsData Resource

```gdscript
class_name SettingsData
extends Resource

@export var music_volume: float = 0.8      # 0.0–1.0
@export var sfx_volume: float = 1.0
@export var use_tilt_controls: bool = true
@export var tilt_sensitivity: float = 1.0   # 0.5–2.0
@export var text_scale: String = "M"        # "S", "M", "L"
@export var high_contrast: bool = false
@export var reduce_motion: bool = false
```

---

## Scene/Node Hierarchy

Each autoload is a plain `Node` (not Node2D or Node3D). They have no scene file — registered directly as scripts.

---

## Signal Interface

### EventBus emits (partial list for this spec):
```
game_state_changed(new_state: GameManager.GameState)
connected_to_server()
disconnected_from_server(reason: String)
network_message_received(msg_type: String, payload: Dictionary)
latency_updated(ms: int)
```

### GameManager listens to:
```
EventBus.network_message_received → handle server-driven state changes
```

### AudioManager listens to:
```
EventBus.music_track_requested(track_id: String, fade_time: float)
EventBus.sfx_requested(sfx_id: String, position: Vector3)
EventBus.game_state_changed → update music for new state
```

---

## Acceptance Criteria

- [ ] `godot/LittleSix/project.godot` opens without errors in Godot 4.6
- [ ] All 5 autoloads load without errors on startup
- [ ] `EventBus` is accessible as `EventBus` from any script (autoloaded)
- [ ] `GameManager.transition_to(GameManager.GameState.LOGO)` runs without error
- [ ] `SaveManager.load_game()` returns `false` on first run (no existing save)
- [ ] `SaveManager.save_game()` creates `user://save.json` with valid JSON
- [ ] `AudioManager.unlock_audio()` runs without error
- [ ] `NetworkManager.state` is `DISCONNECTED` on startup
- [ ] Web export completes without errors (`godot --export-release "Web"`)
- [ ] Linux server export completes without errors
- [ ] All data resource classes can be instantiated: `RacerData.new()` returns valid object

---

## Implementation Notes

1. **Typed signals (Godot 4):** Use `signal foo(bar: int)` syntax, NOT `signal foo`. This enables type checking.
2. **Await over yield:** All async operations use `await signal_name` or `await get_tree().process_frame`, never `yield`.
3. **Callable lambdas:** Connect signals like `EventBus.game_state_changed.connect(func(s): _on_state(s))`, not string-based `connect`.
4. **Server detection:** NetworkManager should detect if running headless via `DisplayServer.get_name() == "headless"` and skip WebSocket init on server builds.
5. **ResourceLoader threading:** For web export, `ResourceLoader.load_threaded_request` is available — use it for loading heavy scenes to avoid blocking the main thread.
