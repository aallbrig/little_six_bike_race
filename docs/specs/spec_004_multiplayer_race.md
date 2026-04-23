# Spec 004 — Multiplayer Race

**Depends on:** Spec 001, Spec 003  
**Last Updated:** 2026-04-10  

---

## Overview

Implement the main race scene: track, riders, physics, game loop (**600 laps**, targeting a 15–20 minute run-time), rider exchange system (Phase 2), the burn mechanic, HUD, and race results. This spec covers everything within the race itself — networking is handled in Spec 005.

The 600-lap target is a product decision; see [ADR 0001](../adr/0001-schedule-alignment-with-little-500.md) and [GDD §8](../GDD.md). In-game lap pacing must average roughly 1.5–2.0 seconds per lap so that a race finishes within the 15–20 minute window.

---

## Requirements

### REQ-004-000: Race Format Variants

The same race scene and controller serves three distinct **race formats**, configured via a `RaceFormat` resource passed to `RaceController` at scene load:

| Format | Lap count | Hard time cap | Source spec |
|---|---|---|---|
| `WEEKLY`  | 150 laps | 5:00 (leader position freezes if exceeded) | [Spec 012 REQ-012-001](spec_012_weekly_races_and_leaderboards.md) |
| `FINALE`  | 600 laps | none | [GDD §8](../GDD.md), [ADR 0001](../adr/0001-schedule-alignment-with-little-500.md) |
| `QUICKPLAY` | 150 laps | 5:00 | Offline drop-in; mirrors WEEKLY for parity |

`RaceFormat` is a plain GDScript `Resource` (`scripts/race/RaceFormat.gd`) with fields `{ laps: int, time_cap_sec: int, allows_momentum: bool }`. The RaceController reads it at `_ready` and exposes `total_laps` and `time_cap_sec` to the HUD. All other race mechanics are identical across formats.

### REQ-004-001: Race Scene Structure
`scenes/race/RaceTrack.tscn` — the main race environment. Must support both single-player (AI only) and multiplayer (mixed human/AI). Format is injected via a `RaceFormat` resource (REQ-004-000).

Required nodes (see TDD Section 5.1 for full hierarchy):
- `WorldEnvironment` with sky gradient and sun light
- `Track` mesh with cinder texture
- `Grandstands` with crowd billboards
- `StartFinishLine` with `BellLapTrigger` (Area3D)
- `PitLane` containing 6 `PitZone` instances (one per team slot)
- `Racers` node containing up to 6 `Rider` instances
- `RaceController` node
- `HUD` (CanvasLayer, loads `HUD.tscn`)
- `Camera3D` (follow-cam for the local player's rider)

### REQ-004-002: Track Geometry
Create the oval track mesh matching Level Design spec (Section 1.2):
- Two 100m straights
- Two turns (40m radius arcs)
- 8m wide racing surface
- Cinder surface material (custom shader or PBR with gravel texture)
- Pit lane on inside of front straight: marked with 6 × 16m colored zones
- Collision boundary: invisible `StaticBody3D` walls along inner and outer edges
- Track direction: clockwise (standard velodrome)

### REQ-004-003: Rider Scene
`scenes/race/Rider.tscn` — a single racer entity.

Node structure:
```
Rider (CharacterBody3D)
├── RiderMesh (MeshInstance3D)          # Rider model
├── BikeMesh (MeshInstance3D)           # Bike model
├── CollisionShape3D (CapsuleShape3D)  # h=1.8m, r=0.3m
├── DraftDetector (Area3D)             # Sphere r=3.0m; detects nearby riders
│   └── CollisionShape3D (SphereShape)
├── SprintTrail (GPUParticles3D)       # Sprint VFX, emitting=false by default
├── AnimationPlayer                    # "pedal", "sprint", "crash", "celebrate", "idle"
└── [script: RiderController.gd or RaceAI.gd]
```

### REQ-004-004: RiderController — Human Input
`scripts/race/RiderController.gd` — handles local player input and physics.

Physics constants (tunable via export vars on RaceController):
```
MAX_SPEED_BASE := 12.0          # m/s (~43 km/h) soft cap; actual top speed emerges from pedal power
SPRINT_SPEED_BONUS := 0.15      # +15% to soft-cap while sprinting
BRAKE_DECEL := 18.0             # m/s² deceleration (coaster brake)
COAST_DECEL := 0.5              # m/s² passive deceleration (no pedaling, no brake)
MAX_STEER_ANGLE := 45.0         # degrees/sec at max steer input
CORNER_SPEED_CAP := 0.85        # fraction of max_speed (crash risk above this in turns)
SPRINT_DRAIN := 25.0            # sprint energy units/sec
SPRINT_REFILL := 10.0           # sprint energy refill units/sec
SPRINT_BAR_MAX := 100.0
SPRINT_LOCKOUT_TIME := 3.0      # seconds after sprint bar empties

# Pedal-power conversion (ADR 0003; GDD §5.2)
WATTS_PER_MPS := 40.0           # rough bike drag constant; adjust during playtest
POWER_DECAY_PER_SEC := 0.85     # accumulated power bleeds out each second if not refreshed

RACE_FATIGUE_BASE_DRAIN := 3.0  # units/sec while riding (pre-stat)
RACE_FATIGUE_SPRINT_BONUS := 4.0 # additional units/sec while sprinting
DRAFT_FATIGUE_REDUCTION := 0.5  # multiplier while drafting (50% reduction)
DRAFT_SPEED_BONUS := 0.03       # base; amplified by Race IQ (GDD §5.2)
```

Stat scaling — all formulas come from [GDD §5.2](../GDD.md):

```gdscript
func _get_soft_cap_speed() -> float:
    # Soft-cap: the bike will not exceed this even if pedal power is high.
    # Power still matters because reaching the cap requires sustained high-quality cadence.
    var power_factor = racer_stats.power / 100.0
    return lerp(MAX_SPEED_BASE * 0.7, MAX_SPEED_BASE * 1.2, power_factor)

func _get_effective_fatigue_drain() -> float:
    var endurance_factor = racer_stats.endurance / 100.0
    return lerp(RACE_FATIGUE_BASE_DRAIN * 1.5, RACE_FATIGUE_BASE_DRAIN * 0.6, endurance_factor)

func _get_effective_recovery_rate() -> float:
    # While coasting or drafting, fatigue bleeds off at this rate.
    return 0.8 + racer_stats.recovery / 25.0        # 0.8 → 4.8/s at 0→100

func _get_draft_speed_bonus() -> float:
    return DRAFT_SPEED_BONUS + racer_stats.race_iq / 500.0   # 0.08 → 0.28 at 0→100

func _get_corner_speed_factor() -> float:
    return 0.55 + racer_stats.handling / 250.0      # 0.55 → 0.95 at 0→100
```

### REQ-004-005: Input Handling — Four-Button Pedal + Steer

Input follows the four-button control scheme specified in [ADR 0003 — Input Control Scheme](../adr/0003-input-control-scheme.md). Buttons are rendered in `RaceInputOverlay.tscn` (see [Spec 007 REQ-007-006](spec_007_mobile_ui_ux.md)).

**Input actions** (defined in `project.godot`):

| Action | Purpose | Default keyboard | Default mobile button |
|---|---|---|---|
| `pedal_left`   | Pedal stroke — left leg  | `A` or `Left Shift`  | Bottom-left, 96×96 px |
| `pedal_right`  | Pedal stroke — right leg | `D` or `Right Shift` | Bottom-right, 96×96 px |
| `steer_left`   | Hold to turn left        | `Left Arrow`         | Upper-left inside, 72×72 px |
| `steer_right`  | Hold to turn right       | `Right Arrow`        | Upper-right inside, 72×72 px |
| `brake`        | Progressive brake        | `Space`              | Bottom-right, above Pedal R, 72×72 px |
| `exchange`     | Relay handoff (Phase 2)  | `E`                  | Bottom-center, 88×88 px, pit-zone only |

**Steering (hold-to-turn, binary):**
```gdscript
func _get_steer_input() -> float:
    var steer := 0.0
    if Input.is_action_pressed("steer_left"):  steer -= 1.0
    if Input.is_action_pressed("steer_right"): steer += 1.0
    # Holding both cancels to straight (0.0). Most-recently-pressed wins on flip.
    return steer
```

Tilt is **no longer a primary input.** It is available as an opt-in accessibility assist (Settings → Controls → "Tilt Assist"). When enabled, tilt is additive to the steer buttons; the buttons always override tilt.

**Pedal cadence (alternating taps produce thrust):**
```gdscript
# RiderController.gd — cadence state
var _last_pedal: String = ""              # "" | "left" | "right"
var _last_pedal_time_ms: int = 0
var _current_cadence_ms: float = 600.0    # target interval, tuned per gear/speed
var _power_accum_watts: float = 0.0

func _on_pedal_pressed(side: String) -> void:
    var now_ms = Time.get_ticks_msec()
    var interval = now_ms - _last_pedal_time_ms

    # Alternation check: must differ from previous pedal to count
    if _last_pedal == side:
        _register_missed_stroke()
        return

    # Timing quality: compare interval to target power window
    var window = _power_window_width_ms()
    var ideal = _current_cadence_ms
    var error = abs(interval - ideal)
    var quality: float
    if error <= window / 2.0:
        quality = 1.0                      # perfect window
    elif error <= window:
        quality = 1.0 - (error - window / 2.0) / (window / 2.0)   # linear falloff
    else:
        quality = 0.0                      # outside window → no power

    _power_accum_watts += _power_per_stroke_watts() * quality
    _last_pedal = side
    _last_pedal_time_ms = now_ms
    EventBus.pedal_stroke.emit(side, quality)   # for HUD feedback & audio

func _power_window_width_ms() -> float:
    # ADR 0003 + GDD §5.2: width driven by Cadence stat, amplified by Season Momentum
    var cadence = racer_stats.cadence                    # 0-100
    var momentum = racer_stats.season_momentum           # 0-10
    var base_ms = 60.0 + cadence * 1.4                   # 60-200 ms at 0→100
    var momentum_mult = 1.0 + (momentum * 0.01)          # +0-10%
    var fatigue_mult = lerp(1.0, 0.55, race_fatigue / 100.0)  # window narrows as you tire
    return base_ms * momentum_mult * fatigue_mult

func _power_per_stroke_watts() -> float:
    # GDD §5.2: Power stat sets ceiling
    return 120.0 + racer_stats.power * 3.8               # 120-500 W at 0→100

func _register_missed_stroke() -> void:
    # Small rhythm penalty: momentarily narrow the next window by ~15%
    _cadence_penalty_timer = 0.5
    EventBus.pedal_missed.emit()
```

The accumulated `_power_accum_watts` bleeds into `current_speed` via the physics step in REQ-004-006. No auto-acceleration anywhere — if the player stops pedaling, the bike coasts.

**Sprint (hold-both-pedals, ≥ 200ms commit):**
```gdscript
var _both_held_since_ms: int = 0

func _process_sprint() -> void:
    var both = Input.is_action_pressed("pedal_left") and Input.is_action_pressed("pedal_right")
    var now = Time.get_ticks_msec()
    if both:
        if _both_held_since_ms == 0:
            _both_held_since_ms = now
        elif now - _both_held_since_ms >= 200 and sprint_energy > 0 and not sprint_locked:
            _sprint_held = true
    else:
        _both_held_since_ms = 0
        _sprint_held = false
```

While `_sprint_held`, alternation is no longer required and the game treats both pedals as simultaneously driving the bike at a higher, Sprint-speed target. Sprint energy drains per existing REQ-004-007.

**The Burn** (Sprint + Exchange in pit zone): unchanged semantics from [GDD §8](../GDD.md) — tap `exchange` while `_sprint_held` and inside the pit zone.

**Accessibility assists** (Settings → Controls, all default OFF):
- `auto_cadence_assist`: single pedal hold substitutes for alternation. In-race ceiling drops by ~10%.
- `steering_assist`: soft racing-line correction when no steer button is pressed.
- `tilt_assist`: additive accelerometer steering, always overridden by steer buttons when pressed.

### REQ-004-006: Coaster Brake Physics + Pedal-Power Integration

The bike does not auto-accelerate. Speed is produced by the pedal-power accumulator fed from REQ-004-005, bounded by a Power-derived soft-cap, and decays when the player stops pedaling. Braking is a dedicated input (coaster-brake framing preserved as visual only — see [ADR 0003 §3](../adr/0003-input-control-scheme.md)).

```gdscript
func _physics_process(delta: float) -> void:
    var steer_input = _get_steer_input()
    var is_braking = Input.is_action_pressed("brake")
    _process_sprint()                              # see REQ-004-005
    var is_sprinting = _sprint_held and sprint_energy > 0 and not sprint_locked

    # Convert accumulated pedal watts into a speed target
    var soft_cap = _get_soft_cap_speed()
    if is_sprinting:
        soft_cap *= (1.0 + SPRINT_SPEED_BONUS)
    var pedal_target_speed = min(_power_accum_watts / WATTS_PER_MPS, soft_cap)

    if is_braking:
        current_speed = move_toward(current_speed, 0.0, BRAKE_DECEL * delta)
    elif pedal_target_speed > current_speed:
        # Accelerate toward the pedal-produced target
        current_speed = move_toward(current_speed, pedal_target_speed, (pedal_target_speed - current_speed) * 3.0 * delta)
    else:
        # Coast — no accel, only friction
        current_speed = move_toward(current_speed, 0.0, COAST_DECEL * delta)

    # Pedal power bleeds out over time (stops ramping if the rider idles)
    _power_accum_watts *= pow(POWER_DECAY_PER_SEC, delta)

    # Apply drafting (stat-scaled bonus)
    if _is_drafting:
        current_speed = min(current_speed * (1.0 + _get_draft_speed_bonus()), soft_cap * 1.05)

    # Steer (binary hold input from REQ-004-005)
    var steer_rad = deg_to_rad(MAX_STEER_ANGLE * steer_input * delta)
    direction = direction.rotated(Vector3.UP, steer_rad)
    direction = direction.normalized()

    # Corner crash check — uses stat-scaled corner tolerance
    if _is_in_turn and current_speed > soft_cap * _get_corner_speed_factor():
        _roll_crash_check(current_speed / soft_cap)

    # Move
    velocity = direction * current_speed
    move_and_slide()

    _update_sprint(delta, is_sprinting)
    _update_race_fatigue(delta, is_sprinting)
```

The visible animation during `is_braking` shows the rider back-pedaling (coaster-brake theme). The actual input is the dedicated brake button.

### REQ-004-007: Sprint System
```gdscript
func _update_sprint(delta: float, is_sprinting: bool) -> void:
    if is_sprinting and sprint_energy > 0:
        sprint_energy = max(0.0, sprint_energy - SPRINT_DRAIN * delta)
        if sprint_energy <= 0:
            sprint_locked = true
            sprint_lock_timer = SPRINT_LOCKOUT_TIME
            EventBus.sprint_exhausted.emit(racer_id)
            AudioManager.play_sfx("bike_sprint_exhaust")
    elif not sprint_locked:
        sprint_energy = min(SPRINT_BAR_MAX, sprint_energy + SPRINT_REFILL * delta)
    
    if sprint_locked:
        sprint_lock_timer -= delta
        if sprint_lock_timer <= 0:
            sprint_locked = false

    # Emit for HUD update (throttled to not spam every frame)
    _sprint_hud_update_timer -= delta
    if _sprint_hud_update_timer <= 0:
        _sprint_hud_update_timer = 0.05  # 20 Hz HUD updates
        EventBus.sprint_energy_changed.emit(racer_id, sprint_energy)
```

### REQ-004-008: Crash System
```gdscript
func _roll_crash_check(speed_ratio: float) -> void:
    # speed_ratio: 1.0 = at base max, >1.0 = over corner cap
    var handling_factor = racer_stats.handling / 100.0
    var base_crash_prob = (speed_ratio - CORNER_SPEED_CAP) * 2.0 / (1.0 - CORNER_SPEED_CAP)
    var adjusted_prob = base_crash_prob * (1.0 - handling_factor * 0.8)
    # adjusted_prob: 0.0–1.0
    
    if randf() < adjusted_prob * delta:  # Per-frame probability (scale by delta)
        _trigger_crash()

func _trigger_crash() -> void:
    if is_crashed: return
    is_crashed = true
    current_speed = 0.0
    animation_player.play("crash")
    EventBus.crash_occurred.emit(racer_id)
    AudioManager.play_sfx("crash_impact")
    await get_tree().create_timer(2.0).timeout
    is_crashed = false
    current_speed = _get_effective_max_speed() * 0.6
    animation_player.play("pedal")
```

### REQ-004-009: Drafting System
`scripts/race/DraftDetector.gd` — Area3D that detects nearby riders behind this rider.

```gdscript
func _check_drafting() -> void:
    var bodies = get_overlapping_bodies()
    _is_drafting = false
    for body in bodies:
        if body == get_parent(): continue
        if not body is CharacterBody3D: continue
        # Check if the other rider is in FRONT (we are behind them)
        var to_other: Vector3 = body.global_position - get_parent().global_position
        var dot = to_other.normalized().dot(get_parent().get_meta("direction", Vector3.FORWARD))
        if dot > 0.7:  # They are in roughly the same direction = we are behind them
            _is_drafting = true
            _draft_source = body
            break

func is_drafting() -> bool:
    return _is_drafting

func get_slingshot_available() -> bool:
    # Slingshot available when drafting and sprint not locked
    return _is_drafting and not get_parent().sprint_locked
```

### REQ-004-010: Pit Zone and Exchange System
`scripts/race/PitZoneDetector.gd` — Area3D at each team's 16m pit zone.

```gdscript
# PitZone.tscn has:
# - Area3D (16m × 2m × 2m box collider along track edge)
# - ColorRect on track surface (team color, opacity 50%)
# - PulseAnimationPlayer (pulses when rider is in zone)

# PitZoneDetector.gd
var team_id: int
var is_active: bool = false

func _on_body_entered(body: Node3D) -> void:
    if body.get_meta("team_id", -1) == team_id:
        is_active = true
        EventBus.pit_zone_entered.emit(body.get_meta("racer_id"))
        # HUD shows exchange button

func _on_body_exited(body: Node3D) -> void:
    if body.get_meta("team_id", -1) == team_id:
        is_active = false
        EventBus.pit_zone_exited.emit(body.get_meta("racer_id"))
        # HUD hides exchange button
```

**Exchange execution:**
```gdscript
# In RiderController
func try_exchange() -> void:
    if not pit_zone_detector.is_active: return
    var is_burn = Input.is_action_pressed("sprint") and Input.is_action_just_pressed("exchange")
    EventBus.exchange_executed.emit(team_id, current_rider_index, next_rider_index, is_burn)
    # Server validates and confirms in multiplayer
    # In single-player: execute immediately
```

**The Burn:**
- `is_burn = true` when Sprint button held + Exchange button tapped simultaneously (within 100ms window)
- Effect: exchange animation plays 0.3s faster, 0.3-second time advantage applied to this team's total time
- Visual: white screen flash + `the_burn_skid` SFX + "BURN!" UI overlay for 1 second

### REQ-004-011: Lap Counting and Race Controller
`scripts/race/RaceController.gd` — authoritative race state (on server in multiplayer; on client in single-player).

```gdscript
const TOTAL_LAPS := 50
const BELL_LAP := TOTAL_LAPS - 1  # Lap 49

var race_started := false
var race_finished := false
var finish_order: Array[int] = []
var racer_laps: Dictionary = {}   # racer_id → int
var racer_times: Dictionary = {}  # racer_id → float (elapsed time at each lap)
var race_start_time: float = 0.0

func _on_start_finish_body_entered(body: Node3D) -> void:
    if not race_started or race_finished: return
    if not body is CharacterBody3D: return
    var racer_id = body.get_meta("racer_id", -1)
    if racer_id == -1: return
    
    # Prevent multiple triggers (rider must cross line, go around, cross again)
    if not _is_valid_crossing(racer_id): return
    
    racer_laps[racer_id] = racer_laps.get(racer_id, 0) + 1
    var current_lap = racer_laps[racer_id]
    var lap_time = Time.get_ticks_msec() / 1000.0 - race_start_time
    
    EventBus.lap_completed.emit(racer_id, current_lap, lap_time)
    _update_positions()
    
    if current_lap == BELL_LAP:
        _trigger_bell_lap()
    
    if current_lap >= TOTAL_LAPS:
        _finish_racer(racer_id)

func _trigger_bell_lap() -> void:
    # Full sprint refill for all riders
    for rider in riders:
        rider.sprint_energy = RiderController.SPRINT_BAR_MAX
        rider.sprint_locked = false
    # Remove draft bonuses (pure speed contest)
    _bell_lap_active = true
    EventBus.bell_lap_triggered.emit()
    AudioManager.play_sfx("bell_lap")
```

### REQ-004-012: Race HUD
`scenes/ui/HUD.tscn` — in-race overlay (CanvasLayer, landscape-oriented). Matches the four-button layout in [ADR 0003 §6](../adr/0003-input-control-scheme.md) and [Spec 007 REQ-007-006](spec_007_mobile_ui_ux.md).

Elements and positions:
```
┌─────────────────────────────────────────┐
│ LAP: 12/{total}  [MINIMAP]   Signal: ●  │  ← top strip
│ POS: 2nd                     PING: 45ms │
│                                         │
│ [◀ STEER L]                [STEER R ▶]  │  ← steer rail (upper-inside)
│                                         │
│            [3D RACE VIEW]               │
│                                         │
│                 [EXCHANGE]              │  ← pit-zone only, bottom-center
│                                         │
│[FATIGUE]                      [SPRINT]  │
│[PEDAL L ▼]         [BRAKE ⬤]  [PEDAL R▼]│  ← pedal + brake row
└─────────────────────────────────────────┘
```

Component specs:
- **Lap counter:** "LAP [N] / {total}" where `{total}` comes from `RaceController.total_laps` (150 for weekly/quickplay, 600 for finale) — Press Start 2P 20px, top-left.
- **Position badge:** "1ST / 2ND / 3RD..." - large crimson badge, top-left below lap.
- **Minimap:** 128×128px SubViewport, top-center.
- **Ping indicator:** small dot + ms number, top-right (green <80ms, amber 80-200ms, red >200ms).
- **Race timer** *(weekly / quickplay only)*: "TIME: 02:14 / 5:00" countdown shown under the minimap; hidden on finale format. Pulses red in the final 30 seconds.
- **Steer Left / Steer Right:** 72×72 px, upper-inside, 12 px inset from the screen edge. Pressed state: crimson fill.
- **Pedal Left / Pedal Right:** 96×96 px, bottom-inside. Flashes briefly on each successful power stroke (color intensity encodes stroke quality from REQ-004-005).
- **Brake button:** 72×72 px circle, bottom-right cluster (between Pedal R and the screen edge's safe-area margin), reachable by the right thumb without leaving Pedal R.
- **Exchange button:** 88×88 px, bottom-center, only visible when in pit zone; pulses with team color.
- **Sprint bar:** vertical gauge, right side above the pedal row, 180px tall × 24px wide, amber fill. Populated from sprint energy.
- **Fatigue arc:** semicircle arc gauge, above Pedal L (bottom-left), 100px radius, color-shifts green→red.
- **Cadence indicator** *(new)*: thin ring around each pedal button that fills as the next ideal stroke window approaches and depletes after it passes. Gives visual rhythm feedback. Color: green inside the power window, amber at edge, grey outside.
- **Momentum badge** *(new, top-left under POS)*: small "🔥 N/10" readout (text only — see Spec 012 REQ-012-011). Hidden if Momentum = 0.

The HUD must render correctly on 375×812 landscape (iPhone SE-ish after rotation) and 430×932 landscape (iPhone 15 Pro Max). Safe-area insets respected per Spec 007 REQ-007-005.

### REQ-004-013: Race Results Scene
`scenes/results/RaceResults.tscn`:

Phase 1 (staggered reveal):
1. Background: track from above (fade in, blurred slightly)
2. Podium: 3D models of top-3 riders rise onto podium platforms (animated)
3. "RACE COMPLETE" header drops in
4. Position list animates in (1st → 6th, staggered 0.3s each):
   - Position number | Racer name | Total time | Fastest lap
5. Local player row highlighted in Crimson
6. CP earned badge animates in under local player row
7. Buttons appear: "RACE AGAIN" (primary) | "RETURN TO HUB" (secondary)
8. If local player placed 1st–3rd: `results_win.ogg`; else `results_loss.ogg`

### REQ-004-014: AI Racer
`scripts/race/RaceAI.gd` — controls AI-driven riders.

AI uses a simple state machine:
```
States:
  FOLLOW_PACK    - stay within 3 bike-lengths of the pack
  DRAFT_TARGET   - draft a specific nearby rider
  ATTACK         - attempt to break away (sprint burst)
  CONSERVE       - reduce effort to recover fatigue

Transitions:
  FOLLOW_PACK → ATTACK: when behind by >2 positions AND race_fatigue < 60
  ATTACK → CONSERVE: when race_fatigue > 75 OR fell back to 1st position
  FOLLOW_PACK → DRAFT_TARGET: when a rider enters draft range
  DRAFT_TARGET → ATTACK: slingshot opportunity (draft long enough, then burst)
```

Rubber-banding:
```gdscript
func _get_ai_speed_modifier() -> float:
    var target_position_rank = 2  # AI tries to stay around 2nd-3rd
    var current_rank = race_controller.get_racer_position(racer_id)
    var spread = current_rank - target_position_rank
    # If AI is too far behind: +10% speed; too far ahead: -10%
    return clamp(1.0 - (spread * 0.05), 0.85, 1.15)
```

---

## Signal Interface

### Emitted via EventBus:
```
race_started()
lap_completed(racer_id, lap_number, lap_time)
racer_position_changed(racer_id, new_position)
pit_zone_entered(racer_id)
pit_zone_exited(racer_id)
exchange_executed(team_id, rider_out, rider_in, is_burn)
sprint_activated(racer_id)
sprint_exhausted(racer_id)
sprint_energy_changed(racer_id, energy)
crash_occurred(racer_id)
bell_lap_triggered()
race_finished(results: Array[RaceResult])
```

### Listens to EventBus:
```
race_countdown_started(seconds) → begin countdown UI
network_message_received("WORLD_STATE", payload) → update remote riders (multiplayer)
network_message_received("RACE_FINISHED", payload) → trigger results
```

---

## Acceptance Criteria

- [ ] Track oval renders with cinder texture, visible pit zones, grandstands
- [ ] 6 riders placed on starting grid at race start
- [ ] Rider moves when steer input applied
- [ ] Brake stops rider within ~2 seconds from max speed
- [ ] Coasting does NOT slow the rider (only brake does)
- [ ] Sprint button accelerates rider, drains sprint bar
- [ ] Sprint lockout triggers at empty sprint bar (3s lockout)
- [ ] Sprint bar refills automatically at 10 units/sec when not sprinting
- [ ] Bell lap fires at lap 49: all sprint bars refill
- [ ] Crash occurs probabilistically at >85% of base max speed in turns
- [ ] Crash: 2-second recovery animation, rider resumes at 60% speed
- [ ] Exchange button appears only when local rider is in pit zone
- [ ] The Burn combo registers (Sprint held + Exchange tapped simultaneously)
- [ ] Burn audio and "BURN!" overlay play on successful burn
- [ ] 600 laps completes the race (lap counter reaches 600/600) within the 15–20 minute target run-time
- [ ] Race results scene shows all 6 positions with times
- [ ] AI riders run the full race without errors
- [ ] Minimap shows all rider positions
- [ ] HUD fatigue arc updates in real-time
- [ ] HUD position badge updates when positions change
