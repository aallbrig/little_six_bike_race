# Technical Design Document — Little Six

**Version:** 1.0  
**Status:** Approved for Implementation  
**Last Updated:** 2026-04-10  

---

## Table of Contents

1. [Technology Stack](#1-technology-stack)
2. [Godot Project Architecture](#2-godot-project-architecture)
3. [Event-Driven Architecture](#3-event-driven-architecture)
4. [Autoload Singletons](#4-autoload-singletons)
5. [Scene Hierarchy](#5-scene-hierarchy)
6. [Data Models](#6-data-models)
7. [Game State Machine](#7-game-state-machine)
8. [Networking Layer](#8-networking-layer)
9. [Training System Implementation](#9-training-system-implementation)
10. [Race Simulation Implementation](#10-race-simulation-implementation)
11. [Save & Persistence Layer](#11-save--persistence-layer)
12. [Performance Targets](#12-performance-targets)
13. [Testing Strategy](#13-testing-strategy)
14. [Build Pipeline](#14-build-pipeline)

---

## 1. Technology Stack

| Layer | Technology | Version | Rationale |
|---|---|---|---|
| Game Engine | Godot | 4.6 | Open-source; web export; GDScript simplicity |
| Client Runtime | WebAssembly + JavaScript | ES2020 | Browser-native; no install |
| Rendering (game) | Forward+ Mobile renderer | — | Balance of visual quality vs. mobile perf |
| Scripting | GDScript | — | Native to Godot; fast iteration |
| Game Server | Godot headless (Linux build) | 4.6 | Same codebase, authoritative simulation |
| Matchmaking API | Node.js | 20 LTS | Lightweight; easy Lambda deployment |
| Real-time Transport | WebSocket Secure (WSS) | RFC 6455 | Only protocol available in mobile browsers |
| Persistence | AWS DynamoDB | — | Serverless; auto-scaling; no idle cost |
| Static Hosting | AWS S3 + CloudFront | — | ~$0.50/month at low traffic |
| Container Runtime | AWS ECS Fargate Spot | — | Pay-per-use; 70% cheaper than on-demand |
| CI/CD | GitHub Actions | — | Free for public repos |

---

## 2. Godot Project Architecture

### 2.1 Project Directory Layout

```
godot/LittleSix/
├── project.godot              # Engine config, autoloads, display settings
├── export_presets.cfg         # Web + Linux server export configs
├── .gitignore
│
├── assets/
│   ├── audio/
│   │   ├── music/             # .ogg files (streaming)
│   │   └── sfx/               # .wav files (loaded in memory)
│   ├── fonts/
│   │   ├── main.tres          # Primary UI font (arcade style)
│   │   └── body.tres          # Body text font
│   ├── models/
│   │   ├── track/             # Track mesh, surface materials
│   │   ├── riders/            # Rider character models
│   │   ├── bikes/             # Bike models (single standardized bike + skins)
│   │   └── environment/       # Grandstands, crowd, skybox
│   ├── textures/              # .webp format (best web compression)
│   └── ui/
│       ├── icons/             # SVG-exported PNGs
│       └── backgrounds/       # Scene backgrounds
│
├── scenes/
│   ├── logo/
│   │   └── Logo.tscn
│   ├── cinematic/
│   │   └── IntroCinematic.tscn
│   ├── title/
│   │   └── TitleScreen.tscn
│   ├── demo/
│   │   └── DemoRace.tscn
│   ├── hub/
│   │   ├── MainHub.tscn
│   │   └── CreateRacer.tscn
│   ├── training/
│   │   ├── TrainingDay.tscn
│   │   └── TrainingResults.tscn
│   ├── race/
│   │   ├── RaceTrack.tscn      # Main race scene
│   │   ├── Rider.tscn          # Individual rider node
│   │   └── PitZone.tscn        # Pit exchange zone node
│   ├── results/
│   │   └── RaceResults.tscn
│   └── ui/
│       ├── HUD.tscn            # In-race HUD overlay
│       ├── Lobby.tscn
│       └── Minimap.tscn
│
├── scripts/
│   ├── autoloads/
│   │   ├── GameManager.gd      # State machine; scene transitions
│   │   ├── NetworkManager.gd   # WebSocket multiplayer peer
│   │   ├── EventBus.gd         # Signal hub (all cross-system events)
│   │   ├── AudioManager.gd     # Music/SFX playback
│   │   └── SaveManager.gd      # Local save data (JSON)
│   ├── race/
│   │   ├── RaceController.gd   # Race loop, lap counting, positions
│   │   ├── RiderController.gd  # Per-rider physics, input, AI
│   │   ├── PitZoneDetector.gd  # Exchange zone collision
│   │   ├── DraftDetector.gd    # Drafting proximity sensor
│   │   └── RaceAI.gd           # AI decision making
│   ├── training/
│   │   ├── TrainingManager.gd  # Training day orchestration
│   │   ├── RacerData.gd        # Racer stat resource
│   │   └── EventRNG.gd         # Random training event system
│   ├── ui/
│   │   ├── HUDController.gd
│   │   ├── LobbyController.gd
│   │   ├── MinimapController.gd
│   │   └── TransitionManager.gd
│   └── network/
│       ├── WebSocketClient.gd
│       ├── MatchmakingClient.gd
│       └── MessageProtocol.gd
│
└── addons/
    └── (third-party plugins if needed)
```

### 2.2 Autoload Registration Order (project.godot)

Autoloads must be registered in dependency order:
1. `EventBus` — no dependencies
2. `SaveManager` — no dependencies
3. `AudioManager` — depends on EventBus
4. `NetworkManager` — depends on EventBus
5. `GameManager` — depends on all others

---

## 3. Event-Driven Architecture

All inter-system communication passes through `EventBus`. No system holds direct references to other systems. Systems emit signals on EventBus; other systems connect to those signals.

### 3.1 EventBus Signal Catalog

```gdscript
# ── Game State ──────────────────────────────────────────
signal game_state_changed(new_state: GameManager.GameState)
signal scene_transition_requested(target_scene: String, data: Dictionary)

# ── Player / Account ────────────────────────────────────
signal player_logged_in(player_data: PlayerData)
signal player_logged_out()
signal racer_created(racer: RacerData)
signal racer_stat_changed(stat: String, old_value: int, new_value: int)

# ── Training ─────────────────────────────────────────────
signal training_day_started(week: int, day: int)
signal training_activity_chosen(activity: TrainingActivity, slot: int)
signal training_activity_resolved(activity: TrainingActivity, changes: Dictionary)
signal training_random_event_fired(event: TrainingEvent)
signal training_day_completed(week: int, day: int, summary: Dictionary)
signal fatigue_threshold_crossed(old_level: String, new_level: String)
signal injury_occurred(stat_affected: String, duration_days: int)

# ── Race ──────────────────────────────────────────────────
signal race_room_joined(room_id: String, room_data: Dictionary)
signal race_countdown_started(seconds: int)
signal race_started()
signal lap_completed(racer_id: int, lap_number: int, lap_time: float)
signal racer_position_changed(racer_id: int, new_position: int)
signal pit_zone_entered(racer_id: int)
signal pit_zone_exited(racer_id: int)
signal exchange_executed(team_id: int, outgoing_rider: int, incoming_rider: int, is_burn: bool)
signal sprint_activated(racer_id: int)
signal sprint_exhausted(racer_id: int)
signal crash_occurred(racer_id: int)
signal bell_lap_triggered()
signal race_finished(results: Array[RaceResult])
signal race_abandoned()

# ── Networking ────────────────────────────────────────────
signal connected_to_server()
signal disconnected_from_server(reason: String)
signal player_joined_room(player_id: int, player_name: String)
signal player_left_room(player_id: int)
signal network_message_received(msg_type: String, payload: Dictionary)
signal latency_updated(ms: int)

# ── Audio ─────────────────────────────────────────────────
signal music_track_requested(track_id: String, fade_time: float)
signal sfx_requested(sfx_id: String, position: Vector3)
```

### 3.2 Event Flow Example — "The Burn"

```
Player input: Sprint + Exchange buttons simultaneously
  → RiderController detects combo within PitZoneDetector.is_active
  → EventBus.emit_signal("exchange_executed", team_id, rider_out, rider_in, true)
  → RaceController listens → awards 0.3s time advantage, swaps active rider
  → HUDController listens → shows "BURN!" text overlay
  → AudioManager listens → plays "burn" SFX
  → NetworkManager listens → broadcasts to server/peers
```

---

## 4. Autoload Singletons

### 4.1 GameManager

Owns the top-level state machine. All scene transitions go through GameManager.

```gdscript
class_name GameManager
extends Node

enum GameState {
    LOGO,
    CINEMATIC,
    TITLE,
    DEMO,
    CREATE_RACER,
    MAIN_HUB,
    TRAINING_DAY,
    TRAINING_RESULTS,
    LOBBY,
    RACE_QUALIFYING,
    RACE_ACTIVE,
    RACE_RESULTS,
    SPRING_EVENT,
    SETTINGS,
}

var current_state: GameState = GameState.LOGO
var current_player: PlayerData = null
var current_season: SeasonData = null

func transition_to(state: GameState, data: Dictionary = {}) -> void
func get_current_scene() -> Node
func _on_scene_loaded(scene: Node) -> void
```

### 4.2 EventBus

Pure signal hub. No logic. See signal catalog above.

```gdscript
class_name EventBus
extends Node
# All signals declared here, nothing else.
```

### 4.3 NetworkManager

Manages WebSocket connection to the game server. Handles connect, disconnect, send, receive.

```gdscript
class_name NetworkManager
extends Node

enum ConnectionState { DISCONNECTED, CONNECTING, CONNECTED, IN_ROOM, IN_RACE }

var state: ConnectionState = ConnectionState.DISCONNECTED
var local_player_id: int = -1
var current_room_id: String = ""
var ping_ms: int = 0

func connect_to_matchmaking(server_url: String) -> void
func join_quick_race() -> void
func join_private_room(room_code: String) -> void
func create_private_room() -> String
func send_message(msg_type: String, payload: Dictionary) -> void
func disconnect_gracefully() -> void
func _on_ws_message(message: String) -> void
```

### 4.4 AudioManager

Wraps Godot's AudioServer. Handles music crossfade and positional SFX.

```gdscript
class_name AudioManager
extends Node

const MUSIC_TRACKS := {
    "attract": "res://assets/audio/music/attract.ogg",
    "hub": "res://assets/audio/music/hub.ogg",
    "training": "res://assets/audio/music/training.ogg",
    "race_normal": "res://assets/audio/music/race_normal.ogg",
    "race_intense": "res://assets/audio/music/race_intense.ogg",
    "results_win": "res://assets/audio/music/results_win.ogg",
    "results_loss": "res://assets/audio/music/results_loss.ogg",
}

func play_music(track_id: String, fade_time: float = 1.0) -> void
func stop_music(fade_time: float = 1.0) -> void
func play_sfx(sfx_id: String, bus: String = "SFX") -> void
func play_sfx_at(sfx_id: String, position: Vector3) -> void
func set_music_volume(db: float) -> void
func set_sfx_volume(db: float) -> void
```

### 4.5 SaveManager

Local save/load using JSON. Mirrors data to server when online.

```gdscript
class_name SaveManager
extends Node

const SAVE_PATH := "user://save.json"

var player_data: PlayerData = null
var settings_data: SettingsData = null

func load_game() -> bool
func save_game() -> void
func wipe_save() -> void
func get_setting(key: String, default: Variant = null) -> Variant
func set_setting(key: String, value: Variant) -> void
func export_save_json() -> String   # For server sync
func import_save_json(json: String) -> void
```

---

## 5. Scene Hierarchy

### 5.1 RaceTrack Scene (most complex)

```
RaceTrack (Node3D)
├── WorldEnvironment
├── DirectionalLight3D
├── Track (MeshInstance3D)
│   ├── CollisionShape3D (track boundary)
│   └── Surface material (cinder texture)
├── Grandstands (Node3D)
│   └── Crowd (AnimatedSprite3D or instanced GPU particles)
├── StartFinishLine (Node3D)
│   └── BellLapTrigger (Area3D)
├── PitLane (Node3D)
│   └── PitZone_{1-6} (PitZone.tscn × 6)  ← one per team
├── Racers (Node3D)
│   └── Rider_{1-6} (Rider.tscn × 6)       ← one per active slot
├── RaceController (Node) [script: RaceController.gd]
├── HUD (CanvasLayer)
│   └── HUD.tscn
└── Camera3D (follows player's rider)
```

### 5.2 Rider Scene

```
Rider (CharacterBody3D)
├── RiderMesh (MeshInstance3D)
│   └── AnimationPlayer (idle, pedal, sprint, crash, celebrate)
├── BikeMesh (MeshInstance3D)
├── CollisionShape3D (capsule)
├── DraftDetector (Area3D) [sphere shape, 2-bike-length radius]
│   └── CollisionShape3D
├── SprintFX (GPUParticles3D)
└── RiderController (script: RiderController.gd)
    └── [or RaceAI.gd for AI-controlled riders]
```

---

## 6. Data Models

All data models are GDScript Resources for serializability.

### 6.1 RacerData

```gdscript
class_name RacerData
extends Resource

@export var racer_id: String = ""
@export var name: String = ""
@export var jersey_color_id: int = 0
@export var background: String = ""

# Permanent stats (0-100)
@export var speed: int = 50
@export var endurance: int = 50
@export var recovery: int = 50
@export var handling: int = 50
@export var team_chem: int = 50

# Transient (not saved between seasons)
@export var fatigue: int = 0
@export var morale: int = 50
@export var is_injured: bool = false
@export var injury_days_remaining: int = 0

func get_race_form() -> String:
    # Returns "HOT" / "WARM" / "COLD" based on recent training
    pass

func apply_training(activity: TrainingActivity) -> Dictionary:
    # Returns dict of stat changes
    pass

func to_dict() -> Dictionary:
    pass

static func from_dict(d: Dictionary) -> RacerData:
    pass
```

### 6.2 PlayerData

```gdscript
class_name PlayerData
extends Resource

@export var player_id: String = ""
@export var display_name: String = "Rider"
@export var is_guest: bool = true
@export var cred_points: int = 0
@export var elo_rating: int = 1000
@export var racer: RacerData = null
@export var current_season: SeasonData = null
@export var career_wins: int = 0
@export var career_races: int = 0
@export var unlocked_cosmetics: Array[String] = []
```

### 6.3 SeasonData

```gdscript
class_name SeasonData
extends Resource

@export var season_id: String = ""
@export var current_week: int = 1
@export var current_day: int = 1  # 1-3 per week
@export var is_race_week: bool = false
@export var qualifying_time: float = 0.0
@export var qualifying_position: int = 0
@export var weeks_completed: Array[WeekData] = []
@export var spring_series_results: Array[EventResult] = []
```

### 6.4 TrainingActivity (enum + static data)

```gdscript
class_name TrainingActivity
extends RefCounted

enum Type {
    SPRINT_INTERVALS,
    LONG_RIDE,
    RECOVERY_SPIN,
    REST_DAY,
    STRENGTH_WORK,
    VIDEO_STUDY,
    TEAM_MEETING,
    NUTRITION_PLAN,
}

const EFFECTS: Dictionary = {
    Type.SPRINT_INTERVALS: { "speed": 3, "fatigue": 4, "morale": 1 },
    Type.LONG_RIDE:        { "endurance": 4, "handling": 1, "fatigue": 3, "morale": 1 },
    Type.RECOVERY_SPIN:    { "recovery": 3, "fatigue": -4, "morale": 2 },
    Type.REST_DAY:         { "recovery": 1, "fatigue": -7, "morale": 3 },
    Type.STRENGTH_WORK:    { "speed": 2, "endurance": 2, "fatigue": 5 },
    Type.VIDEO_STUDY:      { "handling": 4, "morale": 1 },
    Type.TEAM_MEETING:     { "team_chem": 5, "morale": 4 },
    Type.NUTRITION_PLAN:   { "endurance": 2, "recovery": 1, "fatigue": -3, "morale": 1 },
}
```

### 6.5 RaceResult

```gdscript
class_name RaceResult
extends RefCounted

var racer_id: int = -1
var player_name: String = ""
var position: int = 0
var total_time: float = 0.0
var fastest_lap: float = 0.0
var total_laps: int = 0
var exchanges: int = 0
var sprints_used: int = 0
var crashes: int = 0
var is_local_player: bool = false
var cred_points_earned: int = 0
```

### 6.6 NetworkMessage Protocol

All network messages use JSON with this envelope:

```json
{
  "type": "MESSAGE_TYPE",
  "seq": 1234,
  "ts": 1713820800.0,
  "payload": { }
}
```

Message types: see [Network Architecture Document](NETWORK_ARCHITECTURE.md).

---

## 7. Game State Machine

GameManager operates a hierarchical state machine. Transitions are triggered by EventBus signals.

```
LOGO
  └─(timeout)→ CINEMATIC
                └─(complete|skip)→ TITLE
                                    ├─(timeout)→ DEMO
                                    │              └─(timeout)→ CINEMATIC (loop)
                                    └─(tap)→ CREATE_RACER (new) | MAIN_HUB (returning)

CREATE_RACER
  └─(complete)→ MAIN_HUB

MAIN_HUB
  ├─(train)→ TRAINING_DAY
  │           └─(complete)→ TRAINING_RESULTS → MAIN_HUB
  ├─(race)→ LOBBY
  │          └─(race_started)→ RACE_ACTIVE
  │                             └─(race_finished)→ RACE_RESULTS → MAIN_HUB
  └─(spring_event)→ SPRING_EVENT → RACE_RESULTS → MAIN_HUB
```

State transition logic:

```gdscript
func transition_to(new_state: GameState, data: Dictionary = {}) -> void:
    if new_state == current_state:
        return
    _exit_state(current_state)
    current_state = new_state
    EventBus.game_state_changed.emit(new_state)
    _enter_state(new_state, data)

func _enter_state(state: GameState, data: Dictionary) -> void:
    match state:
        GameState.LOGO:
            SceneLoader.load("res://scenes/logo/Logo.tscn")
        GameState.CINEMATIC:
            SceneLoader.load("res://scenes/cinematic/IntroCinematic.tscn")
        GameState.TITLE:
            SceneLoader.load("res://scenes/title/TitleScreen.tscn")
        GameState.DEMO:
            SceneLoader.load("res://scenes/demo/DemoRace.tscn")
        GameState.MAIN_HUB:
            SceneLoader.load("res://scenes/hub/MainHub.tscn")
        GameState.TRAINING_DAY:
            SceneLoader.load("res://scenes/training/TrainingDay.tscn", data)
        GameState.RACE_ACTIVE:
            SceneLoader.load("res://scenes/race/RaceTrack.tscn", data)
        # etc.
```

---

## 8. Networking Layer

See [Network Architecture Document](NETWORK_ARCHITECTURE.md) for full detail.

### 8.1 Transport

```
[Godot Web Client]
      ↕ WSS (wss://gameserver.littlesix.gg/room/{id})
[Godot Linux Server / Node.js Relay]
      ↕ HTTP REST
[Matchmaking Lambda + DynamoDB]
```

### 8.2 Client-Side Prediction

For responsive mobile feel, client-side prediction is applied to the local rider:
- Local rider input is applied immediately (no wait for server ack)
- Server sends authoritative state every 50ms (20 tick/s)
- Client reconciles: if server position differs by > 0.5m, interpolate to server position over 200ms

### 8.3 Connection Flow

```
1. Client calls GET /api/match?type=quick → Lambda returns { server_url, room_id, token }
2. Client connects WSS to server_url with token in header
3. Server validates token → sends JOIN_ACK with room state
4. Client enters lobby
5. Server sends RACE_START when all players ready (or timeout)
6. During race: client sends INPUT_UPDATE every 33ms; server sends WORLD_STATE every 50ms
7. Race ends: server sends RACE_FINISHED with results
8. Client disconnects WSS gracefully
```

---

## 9. Training System Implementation

### 9.1 TrainingManager Flow

```gdscript
class_name TrainingManager
extends Node

signal activity_selected(slot: int, activity: TrainingActivity.Type)
signal day_resolving()
signal day_complete(changes: Dictionary)

var selected_activities: Array[int] = [-1, -1]  # Two slots

func select_activity(slot: int, activity: TrainingActivity.Type) -> void:
    # Validate: REST_DAY fills both slots
    # Validate: same activity not in both slots
    # Validate: fatigue gate (if fatigue ≥ 80, only recovery activities)
    selected_activities[slot] = activity
    EventBus.training_activity_chosen.emit(activity, slot)

func confirm_day() -> void:
    if selected_activities[0] == -1:
        return  # Must select at least one activity
    _resolve_activities()

func _resolve_activities() -> void:
    var total_changes := {}
    for activity_type in selected_activities:
        if activity_type == -1:
            continue
        var changes = _apply_activity(activity_type)
        _merge_changes(total_changes, changes)
    
    # Apply fatigue modifier
    var fatigue_mult = _get_fatigue_multiplier(GameManager.current_player.racer.fatigue)
    _scale_gains(total_changes, fatigue_mult)
    
    # Apply soft cap
    _apply_soft_cap(total_changes)
    
    # Apply to racer
    GameManager.current_player.racer.apply_changes(total_changes)
    
    # Roll for random event
    EventRNG.roll(GameManager.current_player.racer)
    
    EventBus.training_day_completed.emit(
        GameManager.current_season.current_week,
        GameManager.current_season.current_day,
        total_changes
    )
```

### 9.2 Fatigue Multiplier Table

```gdscript
func _get_fatigue_multiplier(fatigue: int) -> float:
    if fatigue <= 30: return 1.1   # Fresh bonus
    if fatigue <= 55: return 1.0   # Normal
    if fatigue <= 70: return 0.8   # Tired
    if fatigue <= 85: return 0.6   # Overloaded
    return 0.4                      # Danger zone
```

---

## 10. Race Simulation Implementation

### 10.1 Physics Approach

Godot `CharacterBody3D` with custom movement (not Godot's physics engine for bike physics — manual velocity integration for predictability).

```gdscript
# RiderController.gd (simplified)
func _physics_process(delta: float) -> void:
    var input_steer := _get_steer_input()   # -1.0 to 1.0
    var is_braking := _get_brake_input()
    var is_sprinting := _get_sprint_input()

    # Calculate target speed
    var target_speed := _calculate_target_speed(is_sprinting)
    
    # Apply coaster brake: only braking reduces speed
    if is_braking:
        current_speed = move_toward(current_speed, 0.0, BRAKE_DECEL * delta)
    else:
        # Accelerate toward target
        current_speed = move_toward(current_speed, target_speed, ACCEL * delta)
    
    # Steer: rotate direction vector
    var steer_amount := input_steer * MAX_STEER_ANGLE * delta
    direction = direction.rotated(Vector3.UP, deg_to_rad(steer_amount))
    
    # Apply drafting modifier
    if draft_detector.is_drafting:
        current_speed *= DRAFT_SPEED_BONUS
        race_fatigue_rate *= DRAFT_FATIGUE_REDUCTION
    
    # Move
    velocity = direction * current_speed
    move_and_slide()
    
    # Update race fatigue
    _update_race_fatigue(delta, is_sprinting, is_braking)
```

### 10.2 Lap Tracking

```gdscript
# RaceController.gd
# Uses a "lap gate" Area3D at start/finish line
func _on_start_finish_gate_body_entered(body: Node3D) -> void:
    if body is Rider:
        var rider: Rider = body
        if _is_valid_lap_crossing(rider):
            rider.laps_completed += 1
            EventBus.lap_completed.emit(rider.racer_id, rider.laps_completed, _get_lap_time(rider))
            _update_race_positions()
            if rider.laps_completed == TOTAL_LAPS - 1:
                EventBus.bell_lap_triggered.emit()
            elif rider.laps_completed >= TOTAL_LAPS:
                _finish_race(rider)
```

### 10.3 AI Racer

AI riders use a simple state machine with rubber-banding:
- States: FOLLOW_PACK, DRAFT_TARGET, ATTACK, CONSERVE
- Rubber-banding: AI speed adjusted ±15% to keep race competitive
- No exploits: AI uses same physics as human riders

---

## 11. Save & Persistence Layer

### 11.1 Local Save Schema (JSON)

```json
{
  "schema_version": 1,
  "player": {
    "player_id": "guest_uuid",
    "display_name": "Rider",
    "is_guest": true,
    "cred_points": 150,
    "elo_rating": 1025
  },
  "racer": {
    "name": "My Racer",
    "jersey_color_id": 2,
    "speed": 58,
    "endurance": 61,
    "recovery": 55,
    "handling": 50,
    "team_chem": 65,
    "fatigue": 20,
    "morale": 72,
    "is_injured": false
  },
  "season": {
    "current_week": 3,
    "current_day": 2,
    "qualifying_time": 0.0
  },
  "settings": {
    "music_volume": 0.8,
    "sfx_volume": 1.0,
    "tilt_sensitivity": 1.0,
    "use_tilt": true,
    "high_contrast": false,
    "text_scale": "M"
  }
}
```

### 11.2 Server Sync

When online, save is synced via REST API after each significant action:
- POST /api/player/save (with JWT)
- Server stores in DynamoDB
- On next login, server save takes precedence if `updated_at` is newer

---

## 12. Performance Targets

| Metric | Target | Fallback |
|---|---|---|
| Frame rate | 60 FPS on mid-range phones | 30 FPS acceptable |
| Initial load time | < 8 seconds on 4G | < 15s on 3G |
| WebAssembly bundle size | < 30MB (compressed) | < 50MB |
| Texture VRAM | < 256MB | < 512MB |
| Network latency tolerance | 150ms playable | 300ms degraded |
| Memory usage (browser tab) | < 512MB | < 800MB |

### 12.1 Mobile Optimization Checklist

- Use Mobile renderer (not Forward+)
- All textures: WebP format, power-of-2 dimensions
- Crowd: GPU particles or 2D sprites on billboard, not full 3D
- LOD: Riders at distance > 20m reduced to low-poly mesh
- Audio: OGG streaming for music; WAV (mono, 22kHz) for SFX
- Shadows: Directional only, low resolution (1024px shadow map)
- Anti-aliasing: FXAA only (TAA too expensive for mobile)

---

## 13. Testing Strategy

### 13.1 Unit Tests (GdUnit4 or gdtest)

Test core logic without rendering:
- `TrainingManager` stat application
- Fatigue multiplier calculation
- Soft cap enforcement
- Lap timing accuracy
- Message protocol encode/decode

### 13.2 Integration Tests

- Full training day cycle (select → resolve → save → reload)
- Race start → lap complete → race finish event chain
- Network message round-trip

### 13.3 Manual QA Checklist (per build)

- Attract mode loops correctly (3 cycles minimum)
- Training day: all 8 activities reachable
- Over-training lock triggers at fatigue ≥ 80
- Injury event fires (forced by debug flag)
- Race: 50 laps completes correctly
- Bell lap audio fires on lap 49 crossing
- Exchange zone button appears/disappears correctly
- The Burn combo registers correctly
- 6-player race with AI bots: no desync crashes
- Mobile tilt controls work in Chrome/Safari iOS

### 13.4 Device Test Matrix

| Device | Browser | Priority |
|---|---|---|
| iPhone 14 (Safari) | Latest iOS Safari | P0 |
| Pixel 7 (Chrome) | Latest Chrome | P0 |
| Samsung Galaxy S22 (Chrome) | Latest Chrome | P1 |
| iPad Air (Safari) | Latest iOS Safari | P1 |
| Desktop Chrome | Latest | P2 |
| Desktop Firefox | Latest | P2 |

---

## 14. Build Pipeline

### 14.1 Godot Web Export

```bash
# Export web build (run from repo root)
godot --headless --export-release "Web" \
  --path godot/LittleSix \
  --export-preset "Web" \
  dist/web/index.html
```

### 14.2 Godot Server Export

```bash
# Export Linux server binary
godot --headless --export-release "Linux Server" \
  --path godot/LittleSix \
  dist/server/little_six_server
```

### 14.3 CI/CD (GitHub Actions)

On push to `main`:
1. Export web build
2. Run unit tests
3. Upload web build to S3 (`s3://little-six-game/latest/`)
4. Build Docker image for server
5. Push to ECR
6. Update ECS task definition

On push to `release/*`:
1. All steps above +
2. Invalidate CloudFront cache
3. Promote ECS deployment to production
